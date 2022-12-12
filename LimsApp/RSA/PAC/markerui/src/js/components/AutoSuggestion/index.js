import React from "react";
import Autosuggest from "react-autosuggest";

import "./autosuggestion.scss";

class Example extends React.Component {
  constructor(props) {
    super(props);

    // Autosuggest is a controlled component.
    // This means that you need to provide an input value
    // and an onChange handler that updates this value (see below).
    // Suggestions also need to be provided to the Autosuggest,
    // and they are initially empty because the Autosuggest is closed.
    this.state = {
      value: "",
      triggerRenderFrom: props.triggerRenderFrom || 1,
      suggestions: props.suggestList || [],
    };
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.suggestList) {
      this.setState({
        // languages: nextProps.suggestList,
        suggestions: nextProps.suggestList,
      });
    }

    if(nextProps.checked != this.props.checked){
      this.setState({
        value: "",
        suggestions: [],
      });
    }
  }

  onChange = (event, { newValue }) => {
    this.setState({ value: newValue });
    this.setState((state) => ({
      value: newValue,
      suggestList: newValue === "" ? [] : state.suggestList,
    }));
  };

  // When suggestion is clicked, Autosuggest needs to populate the input
  // based on the clicked suggestion. Teach Autosuggest how to calculate the
  // input value for every given suggestion.
  getSuggestionValue = (suggestion) => {
    this.props.setvalue(this.props.name, suggestion.id);
    return suggestion.label;
  };

  // Use your imagination to render suggestions.
  renderSuggestion = (suggestion) => <div>{suggestion.label}</div>;

  // Teach Autosuggest how to calculate suggestions for any given input value.
  getSuggestions = (value) => {
    const inputValue = value.trim().toLowerCase();
    const inputLength = inputValue.length;
    const { suggestList } = this.props;
    return suggestList;
  };

  // Autosuggest will call this function every time you need to update suggestions.
  // You already implemented this logic above, so just use it.
  onSuggestionsFetchRequested = ({ value }) => {
    if(value.trim().length >= this.state.triggerRenderFrom)
      this.props.change(value);
  };

  // Autosuggest will call this function every time you need to clear suggestions.
  onSuggestionsClearRequested = () => {
    this.setState({
      suggestions: [],
    });
  };

  shouldRenderSuggestions(value, reason) {
    return true;
  }

  render() {
    const { value, suggestions } = this.state;

    // Autosuggest will pass through all these props to the input.
    const inputProps = {
      placeholder: this.props.placeholder || "Type a programming language",
      value,
      onChange: this.onChange,
    };

    // Finally, render it!
    return (
      <Autosuggest
        suggestions={suggestions}
        onSuggestionsFetchRequested={this.onSuggestionsFetchRequested}
        onSuggestionsClearRequested={this.onSuggestionsClearRequested}
        getSuggestionValue={this.getSuggestionValue}
        shouldRenderSuggestions={this.shouldRenderSuggestions}
        renderSuggestion={this.renderSuggestion}
        inputProps={inputProps}
      />
    );
  }
}
export default Example;
