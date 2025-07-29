module main

import os
import json

pub fn load() !Config {
	config_path := get_config_path()
	
	if !os.exists(config_path) {
		return Config{
			instances: map[string]Instance{}
		}
	}
	
	content := os.read_file(config_path) or {
		return error('failed to read config file: ${err}')
	}
	
	decoded := json.decode(Config, content) or {
		return error('failed to decode JSON: ${err}')
	}
	
	return decoded
}

pub fn (c &Config) save() ! {
	config_path := get_config_path()
	
	content := json.encode_pretty(c)
	
	os.write_file(config_path, content) or {
		return error('failed to write config file: ${err}')
	}
}

pub fn (mut c Config) add_instance(name string, instance Instance) {
	c.instances[name] = instance
}

pub fn (c &Config) get_instance(name string) ?Instance {
	return c.instances[name]
}

pub fn (mut c Config) delete_instance(name string) bool {
	if name in c.instances {
		c.instances.delete(name)
		return true
	}
	return false
}

pub fn (c &Config) list_instances() []string {
	return c.instances.keys()
}

fn get_config_path() string {
	exe_path := os.executable()
	exe_dir := os.dir(exe_path)
	return os.join_path(exe_dir, 'instances.json')
} 