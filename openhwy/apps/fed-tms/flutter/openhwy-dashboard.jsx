import React, { useState } from 'react';
import { ChevronUp, ChevronDown, Terminal, Server, Cloud, Cpu, HardDrive, Activity } from 'lucide-react';

const OpenHWYDashboard = () => {
  const [panelOpen, setPanelOpen] = useState(false);
  const [activeTab, setActiveTab] = useState('systems');

  const systems = [
    { name: 'workbox', status: 'online', cpu: 23, mem: 45, agents: 2 },
    { name: 'helpbox', status: 'online', cpu: 15, mem: 32, agents: 1 },
    { name: 'hostbox', status: 'online', cpu: 8, mem: 28, agents: 1 },
    { name: 'callbox', status: 'online', cpu: 12, mem: 35, agents: 0 },
    { name: 'safebox', status: 'offline', cpu: 0, mem: 0, agents: 0 },
  ];

  const agents = [
    { name: 'HWY', system: 'workbox', status: 'running', type: 'Security & Connections' },
    { name: 'FED', system: 'workbox', status: 'running', type: 'Fleet Director' },
    { name: 'ELDA', system: 'helpbox', status: 'running', type: 'Creator & Architect' },
    { name: 'ECO', system: 'hostbox', status: 'running', type: 'Matching Engine' },
    { name: 'TRAKA', system: 'callbox', status: 'stopped', type: 'Tool Manager' },
  ];

  const tools = [
    'Packet Pilot', 'Whisper Witness', 'Big Bear', 'Cargo Connect',
    'Fuel Factor', 'Iron Insight', 'Night Nexus', 'Zone Zipper',
    'Legal Logger', 'Memory MARK', 'Ghost Guard', 'Jackknife Jailer'
  ];

  return (
    <div className="h-screen w-full bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 text-white flex flex-col overflow-hidden">
      {/* Header */}
      <div className="h-16 bg-black/30 backdrop-blur-sm border-b border-blue-500/30 flex items-center justify-between px-6">
        <div className="flex items-center gap-6">
          <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-400 to-cyan-400 bg-clip-text text-transparent">
            🚛 OpenHWY
          </h1>
          <div className="flex gap-3">
            <button className="px-4 py-1 bg-blue-600/20 hover:bg-blue-600/40 rounded border border-blue-500/50 text-sm">
              open-hwy.com
            </button>
            <button className="px-4 py-1 bg-blue-600/20 hover:bg-blue-600/40 rounded border border-blue-500/50 text-sm">
              fedispatching.com
            </button>
            <button className="px-4 py-1 bg-blue-600/20 hover:bg-blue-600/40 rounded border border-blue-500/50 text-sm">
              8teenwheelers.com
            </button>
          </div>
        </div>
        <div className="flex gap-2">
          <button className="p-2 hover:bg-white/10 rounded">
            <Server className="w-5 h-5" />
          </button>
          <button className="p-2 hover:bg-white/10 rounded">
            <Terminal className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 relative overflow-hidden">
        {/* 3D Perspective Panels */}
        <div className="absolute inset-0 flex items-center justify-center perspective-1000">
          <div className="flex gap-8 transform-gpu" style={{ transform: 'rotateY(-10deg)' }}>
            {/* Left Panel - Community */}
            <div className="w-64 h-96 bg-gradient-to-br from-blue-900/40 to-blue-800/40 backdrop-blur-md rounded-lg border border-blue-500/30 p-4 shadow-2xl">
              <h3 className="text-lg font-semibold mb-3 text-cyan-300">Community</h3>
              <div className="space-y-2 text-sm">
                <div className="flex items-center gap-2">
                  <Cloud className="w-4 h-4" />
                  <span>HWY LogBook</span>
                </div>
                <div className="flex items-center gap-2">
                  <Activity className="w-4 h-4" />
                  <span>Community Datasets</span>
                </div>
              </div>
            </div>

            {/* Center Panel - Freight Services */}
            <div className="w-96 h-[28rem] bg-gradient-to-br from-slate-800/60 to-slate-700/60 backdrop-blur-md rounded-lg border border-cyan-500/30 p-6 shadow-2xl">
              <h2 className="text-2xl font-bold mb-6 text-center bg-gradient-to-r from-cyan-300 to-blue-300 bg-clip-text text-transparent">
                Freight Services
              </h2>
              <div className="grid grid-cols-2 gap-3">
                {[
                  'AI/ML Management',
                  'Transportation Systems',
                  'DevOps Engineering',
                  'Performance Tuning',
                  'Freight Training',
                  'Infrastructure',
                  'Full Stack Dev',
                  'Full Stack Debug',
                  'Agent Development',
                  'Service Development'
                ].map((service, i) => (
                  <button
                    key={i}
                    className="p-3 bg-white/5 hover:bg-white/10 rounded-lg border border-white/10 text-sm transition-all hover:scale-105"
                  >
                    {service}
                  </button>
                ))}
              </div>
            </div>

            {/* Right Panel - Agents & Tools */}
            <div className="w-64 h-96 bg-gradient-to-br from-purple-900/40 to-purple-800/40 backdrop-blur-md rounded-lg border border-purple-500/30 p-4 shadow-2xl">
              <h3 className="text-lg font-semibold mb-3 text-purple-300">Agent Services</h3>
              <div className="space-y-2 text-sm">
                {['EcoX', 'Marketeer', 'ZBoxxy'].map(agent => (
                  <div key={agent} className="p-2 bg-white/5 rounded border border-white/10">
                    {agent}
                  </div>
                ))}
              </div>
              <h3 className="text-lg font-semibold mt-4 mb-2 text-purple-300">Tools</h3>
              <div className="space-y-1 text-xs">
                {['Vision', 'Signal', 'Routing', 'Mobile'].map(tool => (
                  <div key={tool} className="text-white/60">{tool}</div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Sliding Bottom Panel */}
      <div 
        className={`absolute bottom-0 left-0 right-0 bg-black/90 backdrop-blur-xl border-t border-cyan-500/50 transition-all duration-300 ${
          panelOpen ? 'h-80' : 'h-12'
        }`}
      >
        {/* Panel Handle */}
        <div className="h-12 flex items-center justify-between px-6 cursor-pointer" onClick={() => setPanelOpen(!panelOpen)}>
          <div className="flex gap-6">
            <button
              onClick={(e) => { e.stopPropagation(); setActiveTab('systems'); }}
              className={`px-4 py-1 rounded transition-all ${
                activeTab === 'systems' ? 'bg-cyan-500/30 text-cyan-300' : 'text-gray-400 hover:text-white'
              }`}
            >
              Systems
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); setActiveTab('agents'); }}
              className={`px-4 py-1 rounded transition-all ${
                activeTab === 'agents' ? 'bg-cyan-500/30 text-cyan-300' : 'text-gray-400 hover:text-white'
              }`}
            >
              Agents
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); setActiveTab('tools'); }}
              className={`px-4 py-1 rounded transition-all ${
                activeTab === 'tools' ? 'bg-cyan-500/30 text-cyan-300' : 'text-gray-400 hover:text-white'
              }`}
            >
              Tools
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); setActiveTab('logs'); }}
              className={`px-4 py-1 rounded transition-all ${
                activeTab === 'logs' ? 'bg-cyan-500/30 text-cyan-300' : 'text-gray-400 hover:text-white'
              }`}
            >
              Logs
            </button>
          </div>
          <button className="text-cyan-400 hover:text-cyan-300">
            {panelOpen ? <ChevronDown className="w-5 h-5" /> : <ChevronUp className="w-5 h-5" />}
          </button>
        </div>

        {/* Panel Content */}
        {panelOpen && (
          <div className="px-6 pb-6 h-[calc(100%-3rem)] overflow-auto">
            {activeTab === 'systems' && (
              <div className="grid grid-cols-5 gap-4">
                {systems.map(system => (
                  <div key={system.name} className="bg-slate-800/50 rounded-lg p-4 border border-slate-700">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="font-semibold capitalize">{system.name}</h4>
                      <div className={`w-3 h-3 rounded-full ${
                        system.status === 'online' ? 'bg-green-500' : 'bg-red-500'
                      }`} />
                    </div>
                    <div className="text-sm space-y-1 text-gray-400">
                      <div>CPU: {system.cpu}%</div>
                      <div>MEM: {system.mem}%</div>
                      <div>Agents: {system.agents}</div>
                    </div>
                    <button className="mt-3 w-full py-1 bg-cyan-600/20 hover:bg-cyan-600/40 rounded text-xs border border-cyan-500/50">
                      SSH
                    </button>
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'agents' && (
              <div className="grid grid-cols-3 gap-4">
                {agents.map(agent => (
                  <div key={agent.name} className="bg-slate-800/50 rounded-lg p-4 border border-slate-700">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="font-semibold">{agent.name}</h4>
                      <div className={`w-3 h-3 rounded-full ${
                        agent.status === 'running' ? 'bg-green-500' : 'bg-gray-500'
                      }`} />
                    </div>
                    <div className="text-sm text-gray-400 mb-1">{agent.type}</div>
                    <div className="text-xs text-gray-500">{agent.system}</div>
                    <div className="mt-3 flex gap-2">
                      <button className="flex-1 py-1 bg-green-600/20 hover:bg-green-600/40 rounded text-xs border border-green-500/50">
                        Start
                      </button>
                      <button className="flex-1 py-1 bg-red-600/20 hover:bg-red-600/40 rounded text-xs border border-red-500/50">
                        Stop
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'tools' && (
              <div className="grid grid-cols-4 gap-3">
                {tools.map(tool => (
                  <button
                    key={tool}
                    className="p-3 bg-slate-800/50 hover:bg-slate-800/70 rounded-lg border border-slate-700 text-left transition-all"
                  >
                    <div className="text-sm font-medium">{tool}</div>
                    <div className="text-xs text-gray-500 mt-1">Ready</div>
                  </button>
                ))}
              </div>
            )}

            {activeTab === 'logs' && (
              <div className="bg-black/50 rounded-lg p-4 font-mono text-xs space-y-1 h-full overflow-auto">
                <div className="text-green-400">[2024-11-03 03:45:12] System initialized</div>
                <div className="text-blue-400">[2024-11-03 03:45:13] Connecting to systems...</div>
                <div className="text-green-400">[2024-11-03 03:45:14] workbox: Connected</div>
                <div className="text-green-400">[2024-11-03 03:45:15] helpbox: Connected</div>
                <div className="text-green-400">[2024-11-03 03:45:16] hostbox: Connected</div>
                <div className="text-green-400">[2024-11-03 03:45:17] callbox: Connected</div>
                <div className="text-red-400">[2024-11-03 03:45:18] safebox: Connection timeout</div>
                <div className="text-cyan-400">[2024-11-03 03:45:19] HWY agent started on workbox</div>
                <div className="text-cyan-400">[2024-11-03 03:45:20] FED agent started on workbox</div>
                <div className="text-cyan-400">[2024-11-03 03:45:21] ELDA agent started on helpbox</div>
                <div className="text-yellow-400">[2024-11-03 03:45:22] Dashboard ready</div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default OpenHWYDashboard;
