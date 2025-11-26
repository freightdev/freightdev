import React from 'react'

interface BarChartProps {
  data: Array<{
    label: string
    value: number
    color?: string
  }>
  height?: number
  showGrid?: boolean
  horizontal?: boolean
}

export function BarChart({ data, height = 300, showGrid = true, horizontal = false }: BarChartProps) {
  if (!data || data.length === 0) {
    return (
      <div style={{ height: `${height}px` }} className="flex items-center justify-center text-gray-400">
        No data available
      </div>
    )
  }

  const maxValue = Math.max(...data.map((d) => d.value))
  const padding = { top: 20, right: 20, bottom: 40, left: 60 }
  const chartWidth = 100 - padding.left - padding.right
  const chartHeight = 100 - padding.top - padding.bottom

  const barWidth = chartWidth / (data.length * 1.5)
  const barSpacing = (chartWidth / data.length) * 0.5

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
            x1={padding.left}
            y1={padding.top + (chartHeight / 4) * i}
            x2="100"
            y2={padding.top + (chartHeight / 4) * i}
            stroke="rgba(255,255,255,0.1)"
            strokeWidth="0.5"
          />
        ))}

      {/* Y-axis labels */}
      {Array.from({ length: 5 }).map((_, i) => {
        const value = maxValue - (maxValue / 4) * i
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

      {/* Axes */}
      <line
        x1={padding.left}
        y1={padding.top + chartHeight}
        x2="100"
        y2={padding.top + chartHeight}
        stroke="rgba(255,255,255,0.2)"
        strokeWidth="0.5"
      />
      <line
        x1={padding.left}
        y1="0"
        x2={padding.left}
        y2={padding.top + chartHeight}
        stroke="rgba(255,255,255,0.2)"
        strokeWidth="0.5"
      />

      {/* Bars */}
      {data.map((d, i) => {
        const barHeight = (d.value / maxValue) * chartHeight
        const xStart = padding.left + barSpacing + i * (barWidth + barSpacing)
        const yStart = padding.top + chartHeight - barHeight
        const color = d.color || '#d946ef'

        return (
          <g key={`bar-${i}`}>
            {/* Bar with gradient */}
            <defs>
              <linearGradient id={`bar-gradient-${i}`} x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stopColor={color} stopOpacity="1" />
                <stop offset="100%" stopColor={color} stopOpacity="0.6" />
              </linearGradient>
            </defs>
            <rect
              x={xStart}
              y={yStart}
              width={barWidth}
              height={barHeight}
              fill={`url(#bar-gradient-${i})`}
              stroke={color}
              strokeWidth="0.5"
              rx="0.5"
              style={{
                filter: `drop-shadow(0 0 2px ${color}40)`,
              }}
            />
            {/* Value label on top */}
            <text
              x={xStart + barWidth / 2}
              y={yStart - 5}
              textAnchor="middle"
              fontSize="7"
              fill={color}
              fontWeight="600"
            >
              {d.value}
            </text>
            {/* X-axis label */}
            <text
              x={xStart + barWidth / 2}
              y={padding.top + chartHeight + 12}
              textAnchor="middle"
              fontSize="7"
              fill="rgba(255,255,255,0.6)"
            >
              {d.label}
            </text>
          </g>
        )
      })}
    </svg>
  )
}

export default BarChart
