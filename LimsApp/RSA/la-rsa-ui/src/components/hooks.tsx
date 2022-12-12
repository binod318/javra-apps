import { useState } from 'react';

export function useLoading(): {
  loading: number;
  incrementLoader: () => void;
  decrementLoader: () => void;
} {
  const [loading, setLoading] = useState(0);
  const incrementLoader = () => setLoading((loading) => loading + 1);
  const decrementLoader = () => setLoading((loading) => loading - 1);
  return { loading, incrementLoader, decrementLoader };
}
