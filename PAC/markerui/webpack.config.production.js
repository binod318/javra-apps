const webpack = require("webpack");
const { resolve } = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");

const CompressionPlugin = require("compression-webpack-plugin");
const SimpleProgressPlugin = require("simple-progress-webpack-plugin");

const SizePlugin = require("size-plugin");
// let BundleAnalyzerPlugin = require("webpack-bundle-analyzer")
//   .BundleAnalyzerPlugin;

const ExtractTextPlugin = require("extract-text-webpack-plugin");

const MomentLocalesPlugin = require("moment-locales-webpack-plugin");

let inProduction = process.env.NODE_ENV === "production";

let OptimizeCssAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const theme = require(`${__dirname}/src/js/config/antOverride`); // eslint-disable-line

module.exports = {
  entry: [resolve(__dirname, "src", "js", "index.js")],
  output: {
    filename: "bundle.js",
    path: resolve(__dirname, "build"),
  },
  stats: "minimal",
  devtool: "source-map",
  resolve: {
    extensions: [".js", ".jsx", ".json"],
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules\/(?!(auto-bind)\/).*/,
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
              "@ant-design/icons",
            ],
          ],
        },
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: "css-loader",
        }),
      },
      {
        test: /\.scss$/,
        use: ExtractTextPlugin.extract(["css-loader", "sass-loader?sourceMap"]),
      },
      {
        test: /\.less$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: [
            {
              loader: "css-loader",
            },
            {
              loader: "less-loader",
              options: {
                modifyVars: theme,
                javascriptEnabled: true,
              },
            },
          ],
        }),
      },
      {
        test: /\.(woff|woff2|ttf|eot|svg)(\?]?.*)?$/,
        loader: "url-loader?name=res/[name].[ext]?[hash]",
      },
      {
        test: /\.(gif|jpg|png)$/,
        loader: "url-loader?limit=100000",
      },
    ],
  },
  plugins: [
    new SimpleProgressPlugin(),

    new ExtractTextPlugin("style.css"),
    new webpack.LoaderOptionsPlugin({
      minimize: inProduction,
      debug: false,
    }),
    // using production environment
    new webpack.DefinePlugin({
      "process.env": {
        NODE_ENV: JSON.stringify("production"),
      },
    }),

    new webpack.optimize.UglifyJsPlugin({
      sourceMap: true,
    }),
    /*new HtmlWebpackPlugin({
      title: 'PAC',
	  inject: false,
      template: './src/index.html'
    }),*/
    new OptimizeCssAssetsPlugin(),
    new MomentLocalesPlugin({
      localesToKeep: ["en", "en-gb"],
    }),
    // new BundleAnalyzerPlugin(),
  ],
};
