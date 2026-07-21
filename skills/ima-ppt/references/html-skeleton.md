# HTML 技术骨架

每页 slide 共用同一个技术外壳。这个骨架解决两件事：统一资源依赖，统一画布尺寸。骨架内部的布局、排版、装饰完全自由。

所有核心资源托管在 `static.ima.qq.com`。

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=1280">
  <title>Slide Title</title>
  <!-- Tailwind CSS v3 (JIT runtime) -->
  <script src="https://static.ima.qq.com/ima/pptxgen/ajax/libs/tailwind/3.4.17/index.js"></script>
  <!-- Font Awesome 6.5.1 -->
  <link href="https://static.ima.qq.com/ima/pptxgen/ajax/libs/font-awesome/6.5.1/css/all.min.css" rel="stylesheet">
  <!-- 字体（包含完整 Google Fonts 字体集，无需额外引入） -->
  <link href="https://static.ima.qq.com/ima/pptxgen/ajax/libs/fonts/index.css" rel="stylesheet">
  <!-- ECharts 5.6.0: 仅在本页有数据图表时才取消注释引入 -->
  <!-- <script src="https://static.ima.qq.com/ima/pptxgen/ajax/libs/echarts/5.6.0/index.js"></script> -->
  <!-- D3.js v7: 仅在本页需要 D3 可视化时才取消注释引入 -->
  <!-- <script src="https://static.ima.qq.com/ima/pptxgen/ajax/libs/d3/v7/index.js"></script> -->
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
    }
    .slide {
      width: 1280px;
      height: 720px;
      overflow: hidden;
      position: relative;
    }
    /* 
      以下由 Step 2 视觉规划决定：
      - body background-color
      - .slide background-color
      - 自定义字体 class（如 .font-serif, .font-sans 映射到具体字体族）
      - 其他页面自定义样式
    */
  </style>
</head>
<body>
  <div class="slide">
    <!-- 页面内容 -->
  </div>
</body>
</html>
```

## 布局约束

这些不是风格偏好，是硬性约束。`.slide` 是一个 1280×720 的固定画布，强制设置：`width: 1280px; height: 720px; overflow: hidden; position: relative;`。超出范围的内容会被直接裁掉，没有滚动条，没有自适应，溢出就是丢失。

- `<body>` 内有且只有一个 `<div class="slide">` 作为主容器
- body 使用 Flexbox 居中 `.slide`（骨架已内置），不要修改 body 的布局方式
- 背景色/背景图必须设置在 `.slide` 上
- `.slide` 内部使用 Flexbox/Grid 流式布局，确保稳健
- 不使用 CSS 动画（@keyframes/animation/transition），页面元素保持静止。HTML 最终要转为静态 PPTX，动画在转换后会丢失


- 所有内容必须完整显示在 1280×720 范围内。保险做法：给 `.slide` 内部留出 padding（如 `p-10` 或 `p-12`），不要把内容顶到画布边缘
- **空间不足时的降级策略**：先减间距 → 再缩字号 → 最后精简内容。
- **严格禁止**使用 `mt-auto`/`mb-auto` 控制元素位置（易导致溢出，或破坏 flex 容器的对齐逻辑，导致布局异常）