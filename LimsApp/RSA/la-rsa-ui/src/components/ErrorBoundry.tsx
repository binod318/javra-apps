import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Button } from 'antd';
import { useHistory } from 'react-router-dom';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
}

class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
  };

  public static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('Uncaught error:', error, errorInfo);
  }

  public backToSafety(): void {
    const history = useHistory();
    history.push({
      pathname: `/`,
    });
  }

  public render(): React.ReactNode {
    if (this.state.hasError) {
      return (
        <div className='flash-paint'>
          We are sorry, Something went wrong.
          <Button type='primary' onClick={this.backToSafety}>
            Back To Safety
          </Button>
        </div>
      );
    }

    return this.props.children;
  }
}
export default ErrorBoundary;
