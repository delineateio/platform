package logging

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

const defaultLevel = zapcore.WarnLevel

//Delegate to enable sharing of code
type logFunc func(msg string, fields ...zap.Field)

// ILogger interface the logger
type ILogger interface {
	Load()
}

// NewLogger creates an instance of the Logger
func NewLogger(config string) *Logger {

	return &Logger{
		DefaultLevel: zapcore.WarnLevel,
		Level:        getLevel(config),
	}
}

// Logger is the implementation of the logger
type Logger struct {
	DefaultLevel zapcore.Level
	Level        zapcore.Level
}

func getLevel(config string) zapcore.Level {

	// Reads the config value
	var level zapcore.Level
	bytes := []byte(config)
	err := level.UnmarshalText(bytes)
	if err != nil {
		level = defaultLevel
	}

	return level
}

// Load loads the logger based in the config
func (l *Logger) Load() {

	cfg := zap.Config{
		Encoding:         "json",
		Level:            zap.NewAtomicLevelAt(l.Level),
		OutputPaths:      []string{"stderr"},
		ErrorOutputPaths: []string{"stderr"},
		EncoderConfig: zapcore.EncoderConfig{
			MessageKey: "title",

			LevelKey:    "level",
			EncodeLevel: zapcore.CapitalLevelEncoder,

			TimeKey:    "time",
			EncodeTime: zapcore.ISO8601TimeEncoder,
		},
	}

	logger, _ := cfg.Build()
	zap.ReplaceGlobals(logger)
	Info("logger.initialised", "the logger level has been set")
}

// Debug writes a debug message to the underlying logger
func Debug(event string, message string) {

	add(event, message, zap.L().Debug)
}

// Info writes a info message to the underlying logger
func Info(event string, message string) {

	add(event, message, zap.L().Info)
}

// Warn writes a warn message to the underlying logger
func Warn(event string, message string) {

	add(event, message, zap.L().Warn)
}

// Error writes a error message to the underlying logger
func Error(event string, err error) {

	add(event, err.Error(), zap.L().Error)
}

func add(event string, message string, operation logFunc) {

	operation(event,
		zap.String("message", message),
	)
}
