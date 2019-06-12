《基于 JS Hook 技术，打造最先进的在线代理》


# 什么是在线代理

所谓在线代理，就类似本项目的演示，就可通过某个网站访问另一个网站（通常无法直接访问）。不用安装任何插件，不用修改任何配置，仅仅打开一个网页即可。

类似的网站，或许大家都曾见过，并且印象中应该都不怎么好用。相比 ss/v2 这些网络层代理，在线代理的成熟度显然要低得多，只能临时凑合着用。


# 为什么在线代理不好用

因为要实现一个完善的在线代理，难度非常大！

也许你会说，用 nginx 搭个反向代理不就可以了。其实并没有这么简单。

举个例子，假如我们用 `a.com` 反向代理 `b.com`，并且 `b.com` 有如下网页：

```html
<img src="/foo.gif">
<img src="http://b.com/bar.gif">
```

第一个 img 是相对路径。由于当前实际地址是 `a.com`，因此最终访问的 URL 是 `http://a.com/foo.gif`。我们的后端服务器收到请求后，抓取 `http://b.com/foo.gif` 的内容并返回给用户。这没有问题。

第二个 img 是绝对路径，这就有问题了！浏览器会直接访问 `b.com`，根本不经过我们的后端。而 `b.com` 是无法直接访问的，于是图片加载失败。

因此后端在代理网页时，还需要对其中的内容进行处理，将那些 **绝对路径 URL** 替换成自己的地址。例如：

```html
<img src="/foo.gif">
<img src="http://a.com/proxy?url=http://b.com/bar.gif">
```

这样才能确保图 2 走我们的站点，而不是连接 `b.com` 导致逃脱代理。

由此可见，衡量一个在线代理完不完善，很重要的一点就是：能否覆盖网页中尽可能多的 URL，减少逃逸现象。

----

虽然替换网页中的 URL 并不困难，但是，这极其麻烦！

做过 Web 开发的都清楚，网页里的 URL 有千奇百怪的存在形式，可存在于 HTML、CSS、JS 甚至是动态加载的 JSON、XML 等资源中，因此后端只处理 HTML 是不够的，还必须处理各种文本资源！这对服务器是个不小的开销。

除了内容处理，其实还有很多额外开销。互联网上的文本资源大多都是压缩传输，而压缩的数据是无法直接处理的，因此还得先解压；最后处理完的数据，还得再压缩回去。一来一往，消耗不少 CPU。当然也可以不压缩，但这又会增加流量开销。

像过去的 `gzip` 压缩开销尚可接受，而如今流行的 `brotli` 压缩开销非常大。假如用户频繁访问大体积的文本资源，代理服务器 CPU 将严重消耗。

----

不过，上述问题还不是最严重的。事实上 HTML、CSS 等资源都好说，唯独 JS 是个坑 —— 因为 JS 是程序，它可以动态产生 URL。例如：

```js
var site = 'b';
document.write('<img src=http://' + site + '.com/foo.gif>');
```

遇到这种场合，任何字符串层面的替换都是无解的！

除了动态产生 URL，还有动态获取 URL 的情况。因为有很多 API 是和 URL 相关的，例如：

* `document.domain`，`document.URL`，`document.cookie`

* 超链接 `href` 属性，表单 `action` 属性，各种元素 `src` 属性

* 消息事件 `origin` 属性

* 省略数十个 ...

在我们 `a.com` 页面里调用这些 API，返回自然是 `a.com` 的 URL，而不会是 `b.com`。假如网页里的业务逻辑仍以 `b.com` 作为标准处理，很可能就会出现问题。

这类情况现实中很普遍，而传统的在线代理，对此则无能为力。


# 新概念在线代理

现在，我们尝试用更先进的技术，先解决动态 URL 的问题，然后改进服务器的开销问题。

## API Hook

先来思考：在 `a.com` 的网页里，可以让 `document.domain` 返回 `b.com` 吗？

其实可以！因为 JS 非常灵活，绝大部分的原生 API 都可以重写，所以能轻易改变默认行为。例如：

```js
var raw_open = window.open;

window.open = function(url) {
  return raw_open('http://a.com/proxy?' + url);
};
```

这个经过改造的 `open` 函数，可以在每次调用时给 url 加上 `http://a.com/proxy?` 这个前缀。这样，原始网页弹出的任何 URL，其实都是我们站点的页面！

除了函数，属性也可以重写。例如改变 `document.domain` 的 `getter` 和 `setter`：

```js
var fakeDomain = 'b.com';

Object.defineProperty(document, 'domain', {
  get() {
    return fakeDomain;
  },
  set(value) {
    fakeDomain = value;
  }
})
```

通过对函数和属性的重写，我们可以 hook 绝大多数和 URL 相关的 API，在其中对输入的参数或者输出的返回值进行调整。

这样，原本 `b.com` 的网页现在运行于 `a.com` 站点下，页面脚本获得的仍是 `b.com` 的 URL。

我们的代理似乎透明般存在，难以被原始页面感知！


## DOM Hook

增加前端脚本之后，服务端的开销反而变大了。因为除了替换 URL，还得往页面头部注入脚本代码。

既然前端脚本这么强大，可不可以将 URL 的替换也让它来实现？

我们设想下，假如服务端不替换 URL，只注入脚本，那么返回的 HTML 类似这样：

```html
<script src="helper.js"></script>
<html>
  ...
  <img src="http://b.com/foo.gif">
  <script src="http://b.com/bar.js"></script>
</html>
```

我们的脚本可以最先运行，这是个巨大的优势。但是，这能改变后续标签的 URL 属性吗？

事实上，有一个 API 可以拦截 DOM 元素的创建，它就是 `MutationObserver`。通过它，我们可以在 **DOM 元素渲染前** 修改其属性，将绝对路径的 URL 调整成我们的站点。

**尽管服务器返回的 HTML 里都是原始 URL，但资源实际上是从我们的站点加载，超链接指向的也是我们的站点！**

前端有了 `API Hook` 和 `DOM Hook`，后端也就无需处理 JSON、XML 等资源了，因为 URL 无论从何而来，最终都将传给 API，或者赋给 DOM 的属性 —— 这两者现在都能拦截！


## URL Hook

由于 `MutationObserver` 只能拦截 DOM 元素，因此仅适用于 HTML，而无法适用于其他资源，例如 CSS 中也有 URL 字符串，这仍需后端处理。

```css
@import 'http://b.com/foo.css';
.xx {
  background-image: url(http://b.com/bar.gif);
}
```

另外，即使 HTML 中只插入一行代码，服务器仍需对流量进行解压和再压缩，消耗不少 CPU 资源。这很不完美！

因此，我们的终极目标是：服务器不处理任何内容！最多只处理 HTTP 头。

----

为了实现这个目标，需要借助 HTML5 的一个黑科技 —— `Service Worker`。

`Service Worker` 是一种后台运行的服务进程，它提供的 API 允许 JS 拦截当前站点产生的所有 HTTP 请求（甚至包括浏览器地址栏的访问请求），并能控制返回结果，相当于浏览器内部的反向代理！

有了这个 API，我们可统一捕获流量。无论 URL 是绝对路径还是相对路径，无论出现在 HTML 还是 CSS，都能在 `Service Worker` 层进行拦截，然后转发到自己的服务器！

不过 `Service Worker` 本身也需通过脚本安装，那么服务端是否仍需往 HTML 中插入脚本？

其实不需要。因为 `Service Worker` 是后台进程，一旦安装可长期运行，即使网页关闭它仍在运行。所以只需让用户安装一次就可以。

当用户首次访问时，不管访问什么路径，服务端始终返回安装页面。之后，整个站点所有流量都被 `Service Worker` 接管。最终所有的内容处理，都可以由 JS 来实现！服务端只需纯粹转发数据，甚至都不用考虑解压缩，从而大幅降低 CPU 开销。

----

到此，我们实现了三种类型的 Hook：

* API Hook （重写函数和属性）

* DOM Hook （MutationObserver）

* URL Hook  (Service Worker)

现在，无论加载 URL 还是调用 API，都可被我们拦截和代理，仿佛将原始网页嵌套在一个沙盒中运行！


# 无法 Hook 的 API

由于浏览器限制，有些 API 是无法重写的，其中最典型的就是 `location` —— 无论 `window.location` 还是 `document.location` 以及 `location` 对象中的成员，都是无法重写的。

```js
Object.defineProperty(location, 'href', {
  get() {},
  set() {}
})
// Uncaught TypeError: Cannot redefine property: href
```

然而这个 API 使用频率非常高，不少网站通过它检测当前的域名是否合法，例如：

```js
if (location.host != 'b.com') {
  location.href = 'http://b.com';
}
```

如果不考虑这个接口，网站一旦发生跳转，就逃出我们的沙盒了！

然而它又无法重写，这该如何解决？尽管理论上无解，但作为实践，还是可以在一定程度上进行缓解 —— 我们可将 JS 中字面出现的 `location` 进行重命名，例如修改成 `__location`，这样就能将操作**转移到我们定义的对象上**！

```js
if (__location.host != 'b.com') {
  __location.href = 'http://b.com';
}
```

因为 `Service Worker` 掌控所有流量，所以修改 JS 资源并不困难。此外，网页中的内联脚本也可通过 `MutationObserver` 拦截和修改。

> 目前演示站点为了简单，直接使用正则替换，有时会将同名的函数、属性、字符串也进行修改，导致出现误伤。更好的方案，则是在语法树层面进行修改，当然性能开销也会更大。

不过这个方案只能缓解，而无法彻底解决。因为我们只能修改明文出现的 `location`，对于动态的场合就无解了，例如：

```js
self['lo' + 'cat' + 'ion']    // location object
this[atob('bG9jYXRpb24=')]    // location object
```

更别提 `eval` 这些了。所以，如果网页有意访问 `location`，我们是无法拦截的！

这个特征，可以给 Web 开发者一个警示：如果想检测当前页面 URL 是否合法，尽量不要出现明文的 `window`、`location` 等关键字，而是通过动态的方式访问，以防落入上述这种陷阱。如果想检测你的网站是否安全，可尝试用演示站点访问你的登录页，如果没有跳转到原始网站，说明你的 `location` 接口用得不够安全，用户极有可能在代理页面中输入账号密码，导致隐私泄露！


# 无法 Hook 的 DOM

事实上，有些特殊请求无法被 `Service Worker` 拦截，例如 **不同源的框架页面**。因此，我们仍需借助 `MutationObserver` 修改元素的 URL 属性，将跨源的页面变成同源，从而可拦截子页面的所有请求。

不过 `MutationObserver` 也有一些细节问题。例如，即使给元素设置了新的 URL，但是原始 URL 仍会加载。因为浏览器为了提高速度，有一个预加载的机制，原始 URL 在 HTML 解析阶段就开始加载了；之后修改会导致加载取消，但请求仍已产生，控制台里可看到 `cancel` 状态的请求。

有个简单的办法，倒是可以缓解这问题：设置一个 `Content-Security-Policy` 策略，让网页只允许加载自己的域名，从而阻止预加载请求。这个方案目前在演示中开启，可以看到每个页面的头部有一个 `<meta>` 标签定义的 CSP 策略。

当然 `MutationObserver` 仍存在较多问题，这里不一一叙述。事实上最完善的方案，仍是替换 HTML 里的 URL 字符串，并且最好支持流模式。这个功能以后将会实现。


# 无法 Hook 的资源

由于 `URL` 只是 `URI` 的子集，因此有些 URI 资源无法被 `Service Worker` 拦截。最典型的就是 `Data URI`。

此外，还有 `about:`、`blob:`、`javascript:` 等协议的资源加载也无法拦截。这意味着，通过这些 uri 产生的网页，其中的资源都不会被 `Service Worker` 捕获；通过这些 uri 产生的脚本，其中的 `location` 都不会被替换成 `__location`。这就会出现逃逸现象！

因此，我们还得借助 API Hook 和 DOM Hook 来覆盖这类资源的加载。（目前演示中尚未实现）

其他例如 `WebSocket` 协议 `ws:` 和 `wss:`，虽然也不会经过 `Service Worker`，但其本质仍是 HTTP，因此通过 API Hook 即可解决。


# 更多优化

得益于 `Service Worker` 超高的灵活性，我们甚至可对网络架构进行改造，将前后端进行分离：

* 前端只提供静态资源，负责首页展示、`Service Worker` 的安装以及自身脚本

* 后端只提供代理接口，负责数据转发

这样，前端可部署在第三方 Web 服务器上，例如演示站点部署于 GitHub Pages 服务。并且，一个前端可同时使用多个后端服务，从而可实现多倍的带宽加速！

在此基础上，还可以实现负载均衡、故障切换等功能，甚至很多有趣的玩法。。。

例如，我们可将各大网站的常用静态资源，预先部署到本地 CDN 上。用户遇到这些资源时可直接从 CDN 加载，大幅加快访问速度，并能减少代理服务器的流量。

例如，服务器遇到体积较大的静态资源时，只返回文件信息，让用户从流量更廉价的渠道获取完整内容。如果失败，再从原始服务器获取。这样可大幅降低服务器的流量开销。并且这个过程在 `Service Worker` 里实现，上层业务则是毫无感知的。（目前演示网站使用 CloudFlare Worker 作为大文件的下载渠道，流量费用可节省一倍）

----

不过，前后端分离的架构也存在一些缺陷。很多原本浏览器底层实现的功能，现在需要自己来实现，大幅增加了复杂度。例如 Cookie 的增删改查、同源策略的模拟等。目前演示中实现了 Cookie 基本功能，其他的暂未实现。

当然，尽管这个演示还不完善，但这种架构模型，目前是最先进的。搜了国外类似的站点，目前只有 [CroxyProxy](https://www.croxyproxy.com) 这个网站具备 `Service Worker` 和 DOM API Hook 的功能。不过这个网站似乎出现没多久，前端部分还是加密的。另外它没有前后端分离，代理接口是通过 PHP 实现的，相比 nginx 效率和体验都会打折扣，并且 `WebSocket` 也没有实现。

事实上在线代理本不复杂，就看如何使用各种黑科技和巧妙的思路来改进它~
