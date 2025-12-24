```typescript jsx
import React from 'react';
import { useDrag } from 'react-dnd';

// Define the props for LoadCard component
interface LoadCardProps {
  id: string;
  title: string;
}

const LoadCard: React.FC<LoadCardProps> = ({ id, title }) => {
  // Use useDrag hook to make the card draggable
  const [{ isDragging }, drag] = useDrag({
    item: { type: 'LOAD_CARD', id },
    collect: (monitor) => ({
      isDragging: !!monitor.isDragging(),
    }),
  });

  return (
    <div
      ref={drag} // Attach the drag handle to the div element
      className={`p-4 border rounded shadow ${isDragging ? 'opacity-50' : ''}`} // Apply Tailwind CSS classes for styling and opacity when dragging
    >
      {title}
    </div>
  );
};

export default LoadCard;
```
