import { useState } from 'react';

export default function Counter() {
  const [count, setCount] = useState(0);
  return (
    <button
      className="px-4 py-2 rounded-lg bg-gradient-purple text-white font-semibold"
      onClick={() => setCount((value) => value + 1)}
      type="button"
    >
      Clicked {count} times
    </button>
  );
}
