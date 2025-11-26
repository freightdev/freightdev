import React from 'react'

interface LineChartProps {
  data: Array<{
    label: string
    value: number
  }>
  height?: number
  color?: string
  showGrid?: boolean
  animated?: boolean
}

export function LineChart({
  data,
  height = 300,
  color = '#d946ef',
  showGrid = true,
  animated = true,
}: LineChartProps) {
  if (!data || data.length === 0) {
    return (
      <div style={{ height: `${height}px` }} className="flex items-center justify-center text-gray-400">
        No data available
      </div>
    )
  }

  const maxValue = Math.max(...data.map((d) => d.value))
  const minValue = Math.min(...data.map((d) => d.value))
  const range = maxValue - minValue || 1

  const padding = { top: 20, right: 20, bottom: 40, left: 60 }
  const chartWidth = 100 - padding.left - padding.right
  const chartHeight = 100 - padding.top - padding.bottom

  const points = data.map((d, i) => ({
    x: (padding.left + (chartWidth * i) / (data.length - 1 || 1)),
    y: padding.top + chartHeight - ((d.value - minValue) / range) * chartHeight,
    label: d.label,
    value: d.value,
  }))

  const pathD = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ')

  const viewBox = `0 0 100 ${height}`
  const yScale = height / 100

  return (
    <svg
      width="100%"
      height={height}
      viewBox={viewBox}
      className="text-white"
      style={{ overflow: 'visible' }}
    >
      {/* Grid lines */}
      {showGrid &&
        Array.from({ length: 5 }).map((_, i) => (
          <line
            key={`grid-${i}`}
            x1="0"
            y1={padding.top + (chartHeight / 4) * i}
            x2="100"
            y2={padding.top + (chartHeight / 4) * i}
            stroke="rgba(255,255,255,0.1)"
            strokeWidth="0.5"
          />
        ))}

      {/* Y-axis labels */}
      {Array.from({ length: 5 }).map((_, i) => {
        const value = maxValue - (range / 4) * i
        return (
          <text
            key={`label-${i}`}
            x={padding.left - 5}
            y={padding.top + (chartHeight / 4) * i + 2}
            textAnchor="end"
            fontSize="8"
            fill="rgba(255,255,255,0.6)"
          >
            {Math.round(value)}
          </text>
        )
      })}

      {/* X-axis */}
      <line
        x1={padding.left}
        y1={padding.top + chartHeight}
        x2="100"
        y2={padding.top + chartHeight}
        stroke="rgba(255,255,255,0.2)"
        strokeWidth="0.5"
      />

      {/* Y-axis */}
      <line
        x1={padding.left}
        y1="0"
        x2={padding.left}
        y2={padding.top + chartHeight}
        stroke="rgba(255,255,255,0.2)"
        strokeWidth="0.5"
      />

      {/* Line path */}
      <path
        d={pathD}
        fill="none"
        stroke={color}
        strokeWidth="1.5"
        vectorEffect="non-scaling-stroke"
        style={{
          filter: `drop-shadow(0 0 8px ${color}40)`,
        }}
      />

      {/* Gradient fill under line */}
      <defs>
        <linearGradient id="gradient" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor={color} stopOpacity="0.3" />
          <stop offset="100%" stopColor={color} stopOpacity="0" />
        </linearGradient>
      </defs>
      <path
        d={`${pathD} L ${points[points.length - 1].x} ${padding.top + chartHeight} L ${points[0].x} ${padding.top + chartHeight} Z`}
        fill="url(#gradient)"
      />

      {/* Data points */}
      {points.map((p, i) => (
        <circle
          key={`point-${i}`}
          cx={p.x}
          cy={p.y}
          r="2"
          fill={color}
          stroke="rgba(255,255,255,0.2)"
          strokeWidth="1"
          style={{
            filter: `drop-shadow(0 0 3px ${color})`,
          }}
        />
      ))}

      {/* X-axis labels */}
      {points.map((p, i) => {
        if (i % Math.ceil(points.length / 6) === 0 || i === points.length - 1) {
          return (
            <text
              key={`x-label-${i}`}
              x={p.x}
              y={padding.top + chartHeight + 12}
              textAnchor="middle"
              fontSize="7"
              fill="rgba(255,255,255,0.6)"
            >
              {p.label}
            </text>
          )
        }
      })}
    </svg>
  )
}

export default LineChart
