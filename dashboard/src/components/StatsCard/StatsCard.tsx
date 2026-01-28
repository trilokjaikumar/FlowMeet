import { motion } from 'framer-motion';
import { LucideIcon } from 'lucide-react';
import './StatsCard.css';

interface StatsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon: LucideIcon;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  delay?: number;
  gradient?: string;
}

export const StatsCard: React.FC<StatsCardProps> = ({
  title,
  value,
  subtitle,
  icon: Icon,
  trend,
  delay = 0,
  gradient
}) => {
  return (
    <motion.div
      className="stats-card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay }}
    >
      <div className="stats-card-header">
        <div className={`stats-card-icon ${gradient || ''}`}>
          <Icon size={20} strokeWidth={2} />
        </div>
        <span className="stats-card-title">{title}</span>
      </div>
      
      <div className="stats-card-content">
        <div className="stats-card-value">{value}</div>
        
        {subtitle && (
          <div className="stats-card-subtitle">{subtitle}</div>
        )}
        
        {trend && (
          <div className={`stats-card-trend ${trend.isPositive ? 'positive' : 'negative'}`}>
            <span className="trend-arrow">{trend.isPositive ? '↑' : '↓'}</span>
            <span className="trend-value">{Math.abs(trend.value)}%</span>
          </div>
        )}
      </div>
    </motion.div>
  );
};
