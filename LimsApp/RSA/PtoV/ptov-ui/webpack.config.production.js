/**
 * Created by psindurakar on 11/23/2017.
 */
const webpack = require("webpack");
const { resolve } = require("path");
// const HtmlWebpackPlugin = require('html-webpack-plugin');
// const CompressionPlugin = require('compression-webpack-plugin');
// let BundleAnalyzerPlugin = require('webpack-bundle-analyzer')
//   .BundleAnalyzerPlugin;

const ExtractTextPlugin = require("extract-text-webpack-plugin");
const buildEnv = "production"; // 'development'; // production
const OptimizeCssAssetsPlugin = require("optimize-css-assets-webpack-plugin");

module.exports = {
  entry: [resolve(__dirname, "src", "index.js")],
  output: {
    filename: "bundle.js",
    path: resolve(__dirname, "dist")
  },
  stats: "errors-only",
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
          presets: [["es2015", { modules: false }], "react", "stage-2"]
        }
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          fallback: "style-loader",
          use: "css-loader?url=false"
        })
      },
      {
        test: /\.scss$/,
        use: ExtractTextPlugin.extract([
          "css-loader?url=false",
          "sass-loader?sourceMap"
        ])
      },
      {
        test: /\.(woff|woff2|ttf|eot|svg)(\?]?.*)?$/,
        loader: "url-loader?name=res/[name].[ext]?[hash]"
      },
      {
        test: /\.(jpg|png)$/,
        loader: "url-loader?limit=100000"
      }
    ]
  },
  plugins: [
    new ExtractTextPlugin("style.css"),
    new webpack.LoaderOptionsPlugin({
      minimize: false,
      debug: false
    }),
    // using production environment
    new webpack.DefinePlugin({
      "process.env": {
        NODE_ENV: JSON.stringify(buildEnv)
      }
    }),

    new webpack.optimize.UglifyJsPlugin({
      sourceMap: true
    }),
    // new HtmlWebpackPlugin({
    //   title: 'PtoV',
    //   template: './src/index.html'
    // }),
    new ExtractTextPlugin("style.css"),
    new OptimizeCssAssetsPlugin({
      cssProcessorOptions: {
        safe: true
      }
    }),
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
    // new CompressionPlugin({
    //   asset: '[path].gz[query]',
    //   algorithm: 'gzip',
    //   test: /\.js$|\.css$|\.html$/,
    //   threshold: 10240,
    //   minRatio: 0.8
    // })
    // , new BundleAnalyzerPlugin()
  ]
};
