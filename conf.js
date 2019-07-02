jsproxy_config({
  // 当前配置的版本（记录在日志中，用于排查问题）
  ver: '78',

  // 通过 CDN 加速常用网站的静态资源（实验中）
  static_boost: {
    enable: true,
    ver: 20
  },

  // 节点配置
  node_map: {
    'demo-hk': {
      label: '演示服务-香港节点',
      lines: {
        // 主机:权重
        'node-aliyun-hk-0.etherdream.com:8443': 1,
        'node-aliyun-hk-1.etherdream.com:8443': 1,
        'node-aliyun-hk-2.etherdream.com:8443': 1,
      }
    },
    'demo-sg': {
      label: '演示服务-新加坡节点',
      lines: {
        'node-aliyun-sg.etherdream.com:8443': 1,
      },
    },
    'mysite': {
      label: '当前站点',
      lines: {
        [location.host]: 1,
      }
    },
    // 该节点用于加载大体积的静态资源
    'cfworker': {
      label: '',
      hidden: true,
      lines: {
        // 收费版（高权重）
        'node-cfworker.etherdream.com': 6,

        // 免费版（低权重，分摊一些成本）
        // 每个账号每天 10 万次免费请求，但有频率限制
        'a.007.workers.dev': 1,
        'a.hehe.workers.dev': 1,
        'a.lulu.workers.dev': 1,
        'shrill-unit-8594.jsproxy.workers.dev': 1,
      }
    }
  },

  /**
   * 默认节点
   */
  // node_default: 'mysite',
  node_default: /jsproxy\.\w+$/.test(location.host) ? 'demo-hk' : 'mysite',

  /**
   * 加速节点
   */
  node_acc: 'cfworker',

  /**
   * 静态资源 CDN 地址
   * 用于加速 `assets` 目录中的资源访问
   */
  assets_cdn: 'https://cdn.jsdelivr.net/gh/zjcqoo/zjcqoo.github.io@master/assets/',

  // 本地测试时打开，否则访问的是线上的
  // assets_cdn: 'assets/',

  /**
   * 自定义注入页面的 HTML
   */
  inject_html: '<!-- custom html -->',

  /**
   * URL 自定义处理（设计中）
   */
  url_handler: {
    'https://www.baidu.com/img/baidu_resultlogo@2.png': {
      replace: 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png'
    },
    'https://www.pornhub.com/': {
      redir: 'https://php.net/'
    },
    'http://haha.com/': {
      content: 'Hello World'
    },
  }
})