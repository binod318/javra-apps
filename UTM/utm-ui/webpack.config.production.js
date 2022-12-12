const webpack = require("webpack");
const { resolve } = require("path");
// const HtmlWebpackPlugin = require("html-webpack-plugin");

//  const CompressionPlugin = require('compression-webpack-plugin');
//  const SizePlugin = require('size-plugin');
//  let BundleAnalyzerPlugin = require('webpack-bundle-analyzer');
//  .BundleAnalyzerPlugin;
// let WebpackBundleSizeAnalyzerPlugin = require('webpack-bundle-size-analyzer')
//   .WebpackBundleSizeAnalyzerPlugin;

const ExtractTextPlugin = require("extract-text-webpack-plugin");

const MomentLocalesPlugin = require("moment-locales-webpack-plugin");
//  var SimpleProgressPlugin = require('webpack-simple-progress-plugin');

const inProduction = process.env.NODE_ENV === "production";

const OptimizeCssAssetsPlugin = require("optimize-css-assets-webpack-plugin");

module.exports = {
  entry: [resolve(__dirname, "src", "js", "index.js")],
  output: {
    filename: "bundle.js",
    path: resolve(__dirname, "dist")
  },
  stats: "minimal",
  devtool: "source-map",
  resolve: {
    extensions: [".js", ".jsx", ".json"]
  },
  module: {
    rules: [
      {
        // js loading
        test: /\.jsx?$/,
        exclude: /node_modules\/(?!(auto-bind)\/).*/,
        loader: "babel-loader",
        options: {
          babelrc: false,
          presets: ["flow", ["es2015", { modules: false }], "react", "stage-2"]
        }
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: "css-loader"
        })
      },
      {
        test: /\.scss$/,
        use: ExtractTextPlugin.extract(["css-loader", "sass-loader?sourceMap"])
      },
      {
        test: /\.(woff|woff2|ttf|eot|svg)(\?]?.*)?$/,
        loader: "file-loader?name=fonts/[name].[ext]?[hash]"
      },
      {
        test: /\.(gif|jpg|png)$/,
        loader: "file-loader?limit=100000"
      }
    ]
  },
  plugins: [
    new ExtractTextPlugin("style.css"),
    new webpack.LoaderOptionsPlugin({
      minimize: inProduction,
      debug: false
    }),
    // using production environment
    new webpack.DefinePlugin({
      "process.env": {
        NODE_ENV: JSON.stringify("production")
      }
    }),

    new webpack.optimize.UglifyJsPlugin({
      sourceMap: true
    }),
    new OptimizeCssAssetsPlugin(),
    new MomentLocalesPlugin({
      localesToKeep: ["en", "en-gb"]
    })
    // new BundleAnalyzerPlugin(),
  ]
};
