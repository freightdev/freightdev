import React from 'react'

interface PieChartProps {
  data: Array<{
    label: string
    value: number
    color: string
  }>
  size?: number
  donut?: boolean
  showLegend?: boolean
}

export function PieChart({ data, size = 200, donut = false, showLegend = true }: PieChartProps) {
  if (!data || data.length === 0) {
    return (
      <div style={{ width: `${size}px`, height: `${size}px` }} className="flex items-center justify-center text-gray-400">
        No data
      </div>
    )
  }

  const total = data.reduce((sum, item) => sum + item.value, 0)
  const centerX = size / 2
  const centerY = size / 2
  const radius = size / 2 - 20
  const innerRadius = donut ? radius * 0.6 : 0

  let currentAngle = -Math.PI / 2

  const slices = data.map((item) => {
    const sliceAngle = (item.value / total) * Math.PI * 2
    const startAngle = currentAngle
    const endAngle = currentAngle + sliceAngle

    const startX = centerX + radius * Math.cos(startAngle)
    const startY = centerY + radius * Math.sin(startAngle)
    const endX = centerX + radius * Math.cos(endAngle)
    const endY = centerY + radius * Math.sin(endAngle)

    const largeArc = sliceAngle > Math.PI ? 1 : 0

    const innerStartX = centerX + innerRadius * Math.cos(startAngle)
    const innerStartY = centerY + innerRadius * Math.sin(startAngle)
    const innerEndX = centerX + innerRadius * Math.cos(endAngle)
    const innerEndY = centerY + innerRadius * Math.sin(endAngle)

    const pathData = donut
      ? `M ${startX} ${startY} A ${radius} ${radius} 0 ${largeArc} 1 ${endX} ${endY} L ${innerEndX} ${innerEndY} A ${innerRadius} ${innerRadius} 0 ${largeArc} 0 ${innerStartX} ${innerStartY} Z`
      : `M ${centerX} ${centerY} L ${startX} ${startY} A ${radius} ${radius} 0 ${largeArc} 1 ${endX} ${endY} Z`

    const labelAngle = startAngle + sliceAngle / 2
    const labelRadius = donut ? (radius + innerRadius) / 2 : radius * 0.7
    const labelX = centerX + labelRadius * Math.cos(labelAngle)
    const labelY = centerY + labelRadius * Math.sin(labelAngle)
    const percentage = ((item.value / total) * 100).toFixed(1)

    currentAngle = endAngle

    return {
      path: pathData,
      color: item.color,
      label: item.label,
      value: item.value,
      percentage,
      labelX,
      labelY,
    }
  })

  return (
    <div className="flex items-start gap-6">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="flex-shrink-0">
        {slices.map((slice, i) => (
          <g key={`slice-${i}`}>
            <path
              d={slice.path}
              fill={slice.color}
              stroke="rgba(255,255,255,0.1)"
              strokeWidth="0.5"
              style={{
                filter: `drop-shadow(0 0 3px ${slice.color}40)`,
                transition: 'opacity 0.3s ease',
              }}
            />
            {/* Label */}
            <text
              x={slice.labelX}
              y={slice.labelY}
              textAnchor="middle"
              dy="0.3em"
              fontSize="10"
              fontWeight="600"
              fill="white"
              style={{
                pointerEvents: 'none',
              }}
            >
              {slice.percentage}%
            </text>
          </g>
        ))}
      </svg>

      {showLegend && (
        <div className="space-y-2 flex-1">
          {slices.map((slice, i) => (
            <div key={`legend-${i}`} className="flex items-center gap-2">
              <div
                className="w-3 h-3 rounded-full flex-shrink-0"
                style={{ backgroundColor: slice.color }}
              />
              <div className="flex-1 min-w-0">
                <p className="text-sm text-white font-medium truncate">{data[i].label}</p>
                <p className="text-xs text-gray-400">{data[i].value.toLocaleString()}</p>
              </div>
              <p className="text-sm text-gray-400 font-semibold">{slice.percentage}%</p>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default PieChart
