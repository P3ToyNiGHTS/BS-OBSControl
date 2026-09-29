using System;
using Microsoft.Extensions.Logging;
using IPALogger = IPA.Logging.Logger;

namespace OBSControl.Utilities
{
    public sealed class IpaLoggerAdapter<TCategoryName> : ILogger<TCategoryName>
    {
        private readonly IPALogger _ipaLogger;

        public IpaLoggerAdapter(IPALogger ipaLogger)
        {
            _ipaLogger = ipaLogger ?? throw new ArgumentNullException(nameof(ipaLogger));
        }

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull
        {
            return null;
        }

        public bool IsEnabled(LogLevel logLevel)
        {
            return logLevel != LogLevel.None;
        }

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            if (!IsEnabled(logLevel))
            {
                return;
            }

            if (formatter == null)
            {
                throw new ArgumentNullException(nameof(formatter));
            }

            // メッセージのフォーマット
            string message = formatter(state, exception);

            if (exception != null)
            {
                message += $"{Environment.NewLine}{exception}";
            }

            // IPA.Logging への転送
            var ipaLevel = MapLogLevel(logLevel);
            _ipaLogger.Log(ipaLevel, message);
        }

        /// <summary>
        /// Microsoft.Extensions.Logging.LogLevel を IPA.Logging.Logger.Level にマッピングします
        /// </summary>
        private static IPALogger.Level MapLogLevel(LogLevel logLevel)
        {
            return logLevel switch
            {
                LogLevel.Trace => IPALogger.Level.Trace,
                LogLevel.Debug => IPALogger.Level.Debug,
                LogLevel.Information => IPALogger.Level.Info,
                LogLevel.Warning => IPALogger.Level.Warning,
                LogLevel.Error => IPALogger.Level.Error,
                LogLevel.Critical => IPALogger.Level.Critical,
                LogLevel.None => IPALogger.Level.None,
                _ => IPALogger.Level.Info
            };
        }
    }
}
