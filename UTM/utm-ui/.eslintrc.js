module.exports = {
  parser: "babel-eslint",
  extends: ["airbnb", "prettier"],
  plugins: ["import", "prettier"],
  env: {
    node: true,
    browser: true,
    es6: true
  },
  rules: {
    strict: ["error", "global"],
    "function-paren-newline": 0,
    indent: [
      "error",
      2,
      {
        SwitchCase: 1
      }
    ],
    "linebreak-style": ["off", "unix"],
    quotes: ["error", "double"],
    semi: ["error", "always"],
    "comma-dangle": 0,
    "import/no-extraneous-dependencies": [
      "error",
      {
        devDependencies: true
      }
    ],
    "import/prefer-default-export": "off",
    "no-console": 0,
    "jsx-a11y/label-has-for": [0],
    "no-alert": 0,
    "jsx-a11y/anchor-is-valid": 0,
    "no-confirm": 0,
    "global-require": 0,
    "no-underscore-dangle": 0,
    "react/jsx-filename-extension": [
      1,
      {
        extensions: [".js", ".jsx"]
      }
    ],
    "prettier/prettier": [
      "warn",
      {
        singleQuote: false
      }
    ]
  },
  parserOptions: {
    ecmaVersion: 6,
    sourceType: "module",
    ecmaFeatures: {
      jsx: true
    }
  }
};
