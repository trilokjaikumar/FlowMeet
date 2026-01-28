import { motion } from 'framer-motion';
import { Mic, MicOff } from 'lucide-react';
import './AudioVisualizer.css';

interface AudioVisualizerProps {
  isRecording: boolean;
  level?: number;
  showWaveform?: boolean;
}

export const AudioVisualizer: React.FC<AudioVisualizerProps> = ({
  isRecording,
  level = 50,
  showWaveform = true
}) => {
  // Generate bars for visualization
  const bars = Array.from({ length: 40 }, (_, i) => {
    // Create wave pattern
    const baseHeight = Math.sin((i / 40) * Math.PI * 4) * 30 + 40;
    const randomVariation = Math.random() * 20;
    return isRecording ? baseHeight + randomVariation * (level / 100) : 20;
  });

  return (
    <div className="audio-visualizer">
      <div className="visualizer-header">
        <div className="recording-indicator">
          <motion.div
            className={`recording-dot ${isRecording ? 'active' : ''}`}
            animate={isRecording ? { scale: [1, 1.2, 1] } : {}}
            transition={{ duration: 1.5, repeat: Infinity }}
          />
          <span className="recording-status">
            {isRecording ? 'Recording in Progress' : 'Not Recording'}
          </span>
        </div>

        <div className="audio-level">
          <span className="level-label">Level</span>
          <div className="level-bar">
            <motion.div
              className="level-fill"
              style={{ width: `${level}%` }}
              animate={isRecording ? { opacity: [0.7, 1, 0.7] } : {}}
              transition={{ duration: 1, repeat: Infinity }}
            />
          </div>
          <span className="level-value">{Math.round(level)}%</span>
        </div>
      </div>

      {showWaveform && (
        <div className="waveform-container">
          <div className="waveform">
            {bars.map((height, index) => (
              <motion.div
                key={index}
                className="waveform-bar"
                initial={{ height: 20 }}
                animate={{
                  height: isRecording ? height : 20,
                  opacity: isRecording ? 1 : 0.3
                }}
                transition={{
                  duration: 0.1,
                  delay: index * 0.01,
                  repeat: isRecording ? Infinity : 0,
                  repeatDelay: 0.05
                }}
              />
            ))}
          </div>

          <div className="waveform-overlay">
            <motion.div
              className="waveform-pulse"
              animate={isRecording ? {
                x: ['0%', '100%'],
                opacity: [0, 1, 0]
              } : {}}
              transition={{
                duration: 2,
                repeat: Infinity,
                ease: 'linear'
              }}
            />
          </div>
        </div>
      )}

      <div className="visualizer-footer">
        <div className="mic-icon-container">
          {isRecording ? (
            <Mic size={20} className="mic-icon active" />
          ) : (
            <MicOff size={20} className="mic-icon" />
          )}
        </div>
        <p className="visualizer-hint">
          {isRecording 
            ? 'Audio is being captured and will be transcribed after the meeting ends'
            : 'Start a meeting to begin recording'
          }
        </p>
      </div>
    </div>
  );
};
