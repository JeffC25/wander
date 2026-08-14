package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v2"
)

type Config struct {
	ServerConfig `yaml:"server"`
	LogConfig    `yaml:"log"`
	DBConfig     `yaml:"database"`
}

type ServerConfig struct {
	Port               uint16   `yaml:"port"`
	CorsAllowedOrigins []string `yaml:"corsAllowedOrigins"`
}

type DBConfig struct {
	URL string `yaml:"url"`
}

type LogConfig struct {
	Level  int8 `yaml:"level"`
	Pretty bool `yaml:"pretty"`
}

func GetConfig(filePath string) (Config, error) {
	fp := "config.yaml"
	if filePath != "" {
		fp = filePath
	}
	b, err := os.ReadFile(fp)
	if err != nil {
		return Config{}, fmt.Errorf("could not find config file: %v", err)
	}

	c := Config{ServerConfig{}, LogConfig{}, DBConfig{}}
	err = yaml.Unmarshal(b, &c)
	if err != nil {
		return Config{}, fmt.Errorf("failed to unmarshal config into struct: %v", err)
	}
	return c, nil
}
