#!/usr/bin/env python3
"""
AI Training Framework Setup - Main Entry Point
Orchestrates the entire setup process
"""

import sys
import argparse
from pathlib import Path

# Add current directory to path for imports
SCRIPT_DIR = Path(__file__).parent.resolve()
sys.path.insert(0, str(SCRIPT_DIR))

from core.config import Config
from core.logic import SetupOrchestrator
from src.helpers import Logger, Banner


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="AI Training Framework - Complete Setup",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 main.py                    # Interactive mode with prompts
  python3 main.py --force            # Skip all prompts, use config
  python3 main.py --dry-run          # Show what would happen
  python3 main.py --resume           # Resume from last checkpoint
  python3 main.py --force --log setup.log  # Force + custom log
        """
    )
    
    parser.add_argument(
        "--force",
        action="store_true",
        help="Skip all prompts, use config values directly"
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be executed without making changes"
    )
    
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Resume from last checkpoint (if available)"
    )
    
    parser.add_argument(
        "--log",
        type=str,
        default=None,
        help="Custom log file path (default: logs/setup-TIMESTAMP.log)"
    )
    
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Verbose output"
    )
    
    return parser.parse_args()


def main():
    """Main entry point"""
    args = parse_arguments()
    
    # Initialize logger
    logger = Logger(
        verbose=args.verbose,
        log_file=args.log,
        script_dir=SCRIPT_DIR
    )
    
    try:
        # Print banner
        Banner.print_welcome()
        
        # Load configuration
        logger.info("Loading configuration...")
        config = Config(config_dir=SCRIPT_DIR)
        
        # Create orchestrator
        orchestrator = SetupOrchestrator(
            config=config,
            logger=logger,
            force=args.force,
            dry_run=args.dry_run,
            resume=args.resume
        )
        
        # Run setup
        logger.info("Starting setup orchestration...")
        success = orchestrator.execute()
        
        if success:
            Banner.print_success()
            logger.success("✅ Setup completed successfully!")
            return 0
        else:
            logger.error("❌ Setup failed")
            return 1
            
    except KeyboardInterrupt:
        logger.warn("\n⚠️  Setup interrupted by user")
        return 130
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())