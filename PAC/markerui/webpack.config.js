const webpack = require("webpack");
const { resolve } = require("path");
const ExtractTextPlugin = require("extract-text-webpack-plugin");

const port = 9999; // 9091
const theme = require(`${__dirname}/src/js/config/antOverride`); // eslint-disable-line

module.exports = {
  entry: [
    "react-hot-loader/patch",
    `webpack-hot-middleware/client?http://localhost:${port}`, // Setting the URL for the hot reload
    "webpack/hot/only-dev-server", // Reload only the dev server
    resolve(__dirname, "src", "js", "index.js"),
  ],
  output: {
    filename: "bundle.js",
    path: resolve(__dirname, "dist"),
  },
  devtool: "source-map",
  devServer: {
    historyApiFallback: true,
    contentBase: resolve(__dirname, "src"),
    compress: false,
    hot: true,
    host: "0.0.0.0",
    port,
    inline: false,
    disableHostCheck: true, // That solved it
    // https: true,
    stats: "errors-only",
  },
  resolve: {
    extensions: [".js", ".jsx", ".json"],
  },
  module: {
    rules: [
      {
        // js loading
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: "babel-loader",
        options: {
          babelrc: false,
          presets: ["flow", ["es2015", { modules: false }], "react", "stage-2"],
          plugins: [
            "react-hot-loader/babel",
            [
              "import",
              {
                libraryName: "antd",
                libraryDirectory: "es",
                style: true,
              },
              "antd",
            ],
            [
              "import",
              {
                libraryName: "@ant-design/icons",
                libraryDirectory: "es/icons",
                camel2DashComponentName: false,
              },
              "ant-design-icons",
            ],
          ],
        },
      },
      {
        // styles loading
        test: /\.css$/,
        loader: "style-loader?sourceMap!css-loader?sourceMap",
      },
      {
        test: /\.scss$/,
        loader: "style-loader!css-loader?sourceMap!sass-loader?sourceMap",
      },
      {
        test: /\.less$/,
        use: [
          {
            loader: "style-loader",
          },
          {
            loader: "css-loader",
          },
          {
            loader: "less-loader",
            options: {
              javascriptEnabled: true,
              modifyVars: theme,
            },
          },
        ],
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "url-loader?limit=10000&mimetype=application/font-woff",
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "file-loader",
      },
      {
        test: /\.(gif|jpg|png)$/,
        loader: "url-loader?limit=100000",
      },
    ],
  },
  plugins: [
    new webpack.DefinePlugin({
      "process.env": {
        NODE_ENV: JSON.stringify("development"),
      },
    }),
    new webpack.LoaderOptionsPlugin({
      debug: true,
    }),
    new ExtractTextPlugin("style.css"),
    new webpack.HotModuleReplacementPlugin(), // Wire in the hot loading plugin
  ],
};
