module main

import os

fn main() {
	if os.args.len < 2 {
		print_usage()
		exit(1)
	}
	
	command_name := os.args[1]
	
	if command_name in ['help', '-h', '--help'] {
		print_usage()
		return
	}
	
	args := if os.args.len > 2 { os.args[2..] } else { []string{} }
	
	match command_name {
		'configure' {
			configure_command(args) or {
				eprintln('Error: ${err}')
				exit(1)
			}
		}
		'connect' {
			connect_command(args) or {
				eprintln('Error: ${err}')
				exit(1)
			}
		}
		else {
			eprintln('Unknown command: ${command_name}\n')
			print_usage()
			exit(1)
		}
	}
}

fn print_usage() {
	println('Motor Town Server Tool')
	println('')
	println('Usage:')
	println('  motor_town_server_tool_v <command> [args...]')
	println('')
	println('Commands:')
	println('  configure    Configure a new server instance')
	println('  connect      Connect to a server instance')
	println('  help         Show this help message')
	println('')
	println('Examples:')
	println('  motor_town_server_tool_v configure')
	println('  motor_town_server_tool_v connect')
}

fn configure_command(args []string) ! {
	mut cfg := load() or {
		return error('failed to load configuration: ${err}')
	}
	
	for {
		show_menu(cfg)
		
		choice := prompt_choice() or {
			return err
		}
		
		match choice {
			1 {
				add_instance(mut cfg) or {
					eprintln('Error adding instance: ${err}\n')
					continue
				}
			}
			2 {
				if cfg.list_instances().len == 0 {
					println('No instances available to edit.\n')
					continue
				}
				edit_instance(mut cfg) or {
					eprintln('Error editing instance: ${err}\n')
					continue
				}
			}
			3 {
				if cfg.list_instances().len == 0 {
					println('No instances available to delete.\n')
					continue
				}
				delete_instance_menu(mut cfg) or {
					eprintln('Error deleting instance: ${err}\n')
					continue
				}
			}
			0 {
				println('Goodbye!')
				return
			}
			else {
				println('Invalid choice. Please try again.\n')
				continue
			}
		}
		
		cfg.save() or {
			eprintln('Warning: Failed to save configuration: ${err}')
		}
		
		println('')
	}
}

fn show_menu(cfg Config) {
	println('=== Motor Town Server Configuration ===')
	println('')
	
	instances := cfg.list_instances()
	if instances.len > 0 {
		println('Instances:')
		mut sorted_instances := instances.clone()
		sorted_instances.sort()
		
		for name in sorted_instances {
			instance := cfg.get_instance(name) or {
				assert false, 'Instance ${name} should exist in config'
				continue
			}
			println('  - ${name} (${instance.ip}:${instance.port})')
		}
		println('')
	}
	
	println('[1] Add Instance')
	if instances.len > 0 {
		println('[2] Edit Instance')
		println('[3] Delete Instance')
	}
	println('[0] Exit')
	println('')
}

fn prompt_choice() !int {
	print('Enter your choice: ')
	input := os.input('')
	
	choice := input.int()
	assert choice >= 0, 'Choice should be non-negative'
	
	return choice
}

fn add_instance(mut cfg Config) ! {
	println('\n=== Add New Instance ===')
	
	instance_name := prompt_with_retry('Enter instance name: ', validate_instance_name) or {
		return err
	}
	assert instance_name != '', 'Instance name should not be empty after validation'
	
	if instance_name in cfg.instances {
		return error('instance \'${instance_name}\' already exists')
	}
	
	instance := prompt_instance_config() or {
		return err
	}
	assert instance.ip != '', 'IP should not be empty after validation'
	assert instance.port > 0, 'Port should be positive after validation'
	assert instance.password != '', 'Password should not be empty after validation'
	
	cfg.add_instance(instance_name, instance)
	
	println('Instance \'${instance_name}\' added successfully!')
	println('  IP: ${instance.ip}')
	println('  Port: ${instance.port}')
	println('  Password: ${mask_password(instance.password)}')
}

fn edit_instance(mut cfg Config) ! {
	println('\n=== Edit Instance ===')
	
	instances := cfg.list_instances()
	mut sorted_instances := instances.clone()
	sorted_instances.sort()
	assert sorted_instances.len > 0, 'Should have instances to edit'
	
	println('Available instances:')
	for i, name in sorted_instances {
		instance := cfg.get_instance(name) or {
			assert false, 'Instance ${name} should exist'
			continue
		}
		println('[${i + 1}] ${name} (${instance.ip}:${instance.port})')
	}
	println('')
	
	print('Enter instance number to edit: ')
	input := os.input('')
	choice := input.int()
	
	if choice < 1 || choice > sorted_instances.len {
		return error('invalid choice: ${input}')
	}
	
	instance_name := sorted_instances[choice - 1]
	existing := cfg.get_instance(instance_name) or {
		assert false, 'Selected instance should exist'
		return error('instance not found')
	}
	
	println('\nEditing instance \'${instance_name}\'')
	println('Current: ${existing.ip}:${existing.port}')
	println('Enter new values (press Enter to keep current value):')
	
	new_instance := prompt_instance_config_with_defaults(existing) or {
		return err
	}
	
	cfg.add_instance(instance_name, new_instance)
	
	println('Instance \'${instance_name}\' updated successfully!')
	println('  IP: ${new_instance.ip}')
	println('  Port: ${new_instance.port}')
	println('  Password: ${mask_password(new_instance.password)}')
}

fn delete_instance_menu(mut cfg Config) ! {
	println('\n=== Delete Instance ===')
	
	instances := cfg.list_instances()
	mut sorted_instances := instances.clone()
	sorted_instances.sort()
	assert sorted_instances.len > 0, 'Should have instances to delete'
	
	println('Available instances:')
	for i, name in sorted_instances {
		instance := cfg.get_instance(name) or {
			assert false, 'Instance ${name} should exist'
			continue
		}
		println('[${i + 1}] ${name} (${instance.ip}:${instance.port})')
	}
	println('')
	
	print('Enter instance number to delete: ')
	input := os.input('')
	choice := input.int()
	
	if choice < 1 || choice > sorted_instances.len {
		return error('invalid choice: ${input}')
	}
	
	instance_name := sorted_instances[choice - 1]
	
	print('Are you sure you want to delete instance \'${instance_name}\'? (y/N): ')
	confirmation := os.input('').to_lower().trim_space()
	
	if confirmation != 'y' && confirmation != 'yes' {
		println('Deletion cancelled.')
		return
	}
	
	success := cfg.delete_instance(instance_name)
	assert success, 'Instance deletion should succeed for existing instance'
	
	println('Instance \'${instance_name}\' deleted successfully!')
}

fn prompt_instance_config() !Instance {
	ip := prompt_with_retry('Enter server IP: ', validate_ip) or {
		return err
	}
	assert ip != '', 'IP should not be empty after validation'
	
	port_str := prompt_with_retry('Enter server port: ', validate_port) or {
		return err
	}
	port := port_str.int()
	assert port > 0, 'Port should be positive after validation'
	
	password := prompt_with_retry('Enter server password: ', validate_password) or {
		return err
	}
	assert password != '', 'Password should not be empty after validation'
	
	return Instance{
		ip: ip
		port: port
		password: password
	}
}

fn prompt_instance_config_with_defaults(existing Instance) !Instance {
	ip := prompt_with_defaults('Enter server IP', existing.ip, validate_ip) or {
		return err
	}
	assert ip != '', 'IP should not be empty after validation'
	
	port_str := prompt_with_defaults('Enter server port', existing.port.str(), validate_port) or {
		return err
	}
	port := port_str.int()
	assert port > 0, 'Port should be positive after validation'
	
	password := prompt_with_defaults('Enter server password', existing.password, validate_password) or {
		return err
	}
	assert password != '', 'Password should not be empty after validation'
	
	return Instance{
		ip: ip
		port: port
		password: password
	}
}

fn prompt_with_retry(prompt string, validator fn(string) !) !string {
	max_attempts := 3
	assert max_attempts > 0, 'Max attempts should be positive'
	
	for attempt in 1 .. max_attempts + 1 {
		print(prompt)
		input := os.input('').trim_space()
		
		validator(input) or {
			eprintln('Error: ${err}')
			if attempt < max_attempts {
				eprintln('Please try again (${max_attempts - attempt}/${max_attempts} attempts remaining).')
			} else {
				return error('maximum attempts reached (${max_attempts}/${max_attempts})')
			}
			continue
		}
		
		assert input != '' || prompt.contains('password'), 'Input should not be empty for most prompts'
		return input
	}
	
	assert false, 'Should not reach here'
	return error('unexpected error in retry loop')
}

fn prompt_with_defaults(prompt string, default_value string, validator fn(string) !) !string {
	max_attempts := 3
	assert max_attempts > 0, 'Max attempts should be positive'
	assert default_value != '', 'Default value should not be empty'
	
	for attempt in 1 .. max_attempts + 1 {
		print('${prompt} [${default_value}]: ')
		input := os.input('').trim_space()
		
		final_input := if input == '' { default_value } else { input }
		
		validator(final_input) or {
			eprintln('Error: ${err}')
			if attempt < max_attempts {
				eprintln('Please try again (${max_attempts - attempt}/${max_attempts} attempts remaining).')
			} else {
				return error('maximum attempts reached (${max_attempts}/${max_attempts})')
			}
			continue
		}
		
		assert final_input != '', 'Final input should not be empty'
		return final_input
	}
	
	assert false, 'Should not reach here'
	return error('unexpected error in retry loop')
}

fn connect_command(args []string) ! {
	mut cfg := load() or {
		return error('failed to load configuration: ${err}')
	}
	
	instances := cfg.list_instances()
	if instances.len == 0 {
		println('No instances configured. Use \'configure\' command to add instances.')
		return
	}
	
	instance, instance_name := select_instance(cfg, instances) or {
		return err
	}
	
	println('Connected to instance \'${instance_name}\' (${instance.ip}:${instance.port})')
	println('Type \'help\' for available commands or \'exit\' to disconnect.')
	println('')
	
	start_shell(instance, instance_name) or {
		return err
	}
}

fn select_instance(cfg Config, instances []string) !(Instance, string) {
	mut sorted_instances := instances.clone()
	sorted_instances.sort()
	assert sorted_instances.len > 0, 'Should have instances to connect to'
	
	println('=== Available Instances ===')
	for i, name in sorted_instances {
		instance := cfg.get_instance(name) or {
			assert false, 'Instance ${name} should exist'
			continue
		}
		println('[${i + 1}] ${name} (${instance.ip}:${instance.port})')
	}
	println('')
	
	print('Select instance to connect to: ')
	input := os.input('')
	choice := input.int()
	
	if choice < 1 || choice > sorted_instances.len {
		return error('invalid choice: ${input}')
	}
	
	instance_name := sorted_instances[choice - 1]
	instance := cfg.get_instance(instance_name) or {
		assert false, 'Selected instance should exist'
		return error('instance not found')
	}
	
	return instance, instance_name
}

fn start_shell(instance Instance, instance_name string) ! {
	for {
		print('${instance_name}> ')
		
		input := os.input('').trim_space()
		if input == '' {
			continue
		}
		
		parts := input.split(' ')
		command := parts[0].to_lower()
		
		match command {
			'exit', 'quit', 'disconnect' {
				println('Disconnected from instance \'${instance_name}\'')
				return
			}
			'help' {
				show_shell_help()
			}
			'chat' {
				handle_chat_command(parts, instance) or {
					eprintln('Error: ${err}')
				}
			}
			'players', 'playerlist' {
				handle_player_list_command(instance) or {
					eprintln('Error: ${err}')
				}
			}
			'count', 'playercount' {
				handle_player_count_command(instance) or {
					eprintln('Error: ${err}')
				}
			}
			'banlist' {
				handle_ban_list_command(instance) or {
					eprintln('Error: ${err}')
				}
			}
			'kick' {
				handle_kick_command(parts, instance) or {
					eprintln('Error: ${err}')
				}
			}
			'ban' {
				handle_ban_command(parts, instance) or {
					eprintln('Error: ${err}')
				}
			}
			'unban' {
				handle_unban_command(parts, instance) or {
					eprintln('Error: ${err}')
				}
			}
			'version' {
				handle_version_command(instance) or {
					eprintln('Error: ${err}')
				}
			}
			'housing' {
				handle_housing_command(instance) or {
					eprintln('Error: ${err}')
				}
			}
			else {
				eprintln('Unknown command: ${command}')
				println('Type \'help\' for available commands.')
			}
		}
	}
}

fn show_shell_help() {
	println('Available commands:')
	println('  chat <message>        Send a chat message to the server')
	println('  players, playerlist   Get list of online players')
	println('  count, playercount    Get number of online players')
	println('  banlist               Get list of banned players')
	println('  kick <unique_id>      Kick a player by unique ID')
	println('  ban <unique_id> [hours] [reason]  Ban a player')
	println('  unban <unique_id>     Unban a player by unique ID')
	println('  version               Get server version')
	println('  housing               Get housing list')
	println('  help                  Show this help message')
	println('  exit                  Disconnect and return to main menu')
	println('')
}

fn handle_chat_command(parts []string, instance Instance) ! {
	if parts.len < 2 {
		return error('usage: chat <message>')
	}
	
	message := parts[1..].join(' ')
	assert message != '', 'Message should not be empty after joining parts'
	
	println('Sending message: ${message}')
	
	response := send_chat_message(instance, message) or {
		return error('failed to send chat message: ${err}')
	}
	
	println('✓ Message sent successfully: ${response.message}')
}

fn handle_player_list_command(instance Instance) ! {
	response := get_player_list(instance) or {
		return error('failed to get player list: ${err}')
	}
	
	if response.data.len == 0 {
		println('No players online')
		return
	}
	
	println('Online players (${response.data.len}):')
	for key, value in response.data {
		// Parse the player data from the response
		println('  - Player ${key}: ${value}')
	}
}

fn handle_player_count_command(instance Instance) ! {
	response := get_player_count(instance) or {
		return error('failed to get player count: ${err}')
	}
	
	if num_players_str := response.data['num_players'] {
		num_players := num_players_str.int()
		println('Players online: ${num_players}')
	} else {
		return error('unexpected player count format in response')
	}
}

fn handle_ban_list_command(instance Instance) ! {
	response := get_ban_list(instance) or {
		return error('failed to get ban list: ${err}')
	}
	
	if response.data.len == 0 {
		println('No banned players')
		return
	}
	
	println('Banned players (${response.data.len}):')
	for key, value in response.data {
		println('  - Player ${key}: ${value}')
	}
}

fn handle_kick_command(parts []string, instance Instance) ! {
	if parts.len < 2 {
		return error('usage: kick <unique_id>')
	}
	
	unique_id := parts[1]
	assert unique_id != '', 'Unique ID should not be empty'
	
	println('Kicking player with ID: ${unique_id}')
	
	response := kick_player(instance, unique_id) or {
		return error('failed to kick player: ${err}')
	}
	
	println('✓ Player kicked successfully: ${response.message}')
}

fn handle_ban_command(parts []string, instance Instance) ! {
	if parts.len < 2 {
		return error('usage: ban <unique_id> [hours] [reason]')
	}
	
	unique_id := parts[1]
	mut hours := 0
	mut reason := ''
	
	if parts.len > 2 {
		hours = parts[2].int()
	}
	
	if parts.len > 3 {
		reason = parts[3..].join(' ')
	}
	
	assert unique_id != '', 'Unique ID should not be empty'
	
	print('Banning player with ID: ${unique_id}')
	if hours > 0 {
		print(' for ${hours} hours')
	}
	if reason != '' {
		print(' (reason: ${reason})')
	}
	println('')
	
	response := ban_player(instance, unique_id, hours, reason) or {
		return error('failed to ban player: ${err}')
	}
	
	println('✓ Player banned successfully: ${response.message}')
}

fn handle_unban_command(parts []string, instance Instance) ! {
	if parts.len < 2 {
		return error('usage: unban <unique_id>')
	}
	
	unique_id := parts[1]
	assert unique_id != '', 'Unique ID should not be empty'
	
	println('Unbanning player with ID: ${unique_id}')
	
	response := unban_player(instance, unique_id) or {
		return error('failed to unban player: ${err}')
	}
	
	println('✓ Player unbanned successfully: ${response.message}')
}

fn handle_version_command(instance Instance) ! {
	response := get_version(instance) or {
		return error('failed to get version: ${err}')
	}
	
	if version := response.data['version'] {
		println('Server version: ${version}')
	} else {
		return error('unexpected version format in response')
	}
}

fn handle_housing_command(instance Instance) ! {
	response := get_housing_list(instance) or {
		return error('failed to get housing list: ${err}')
	}
	
	if response.data.len == 0 {
		println('No housing data available')
		return
	}
	
	println('Housing list (${response.data.len} entries):')
	for house_name, house_data in response.data {
		println('  - ${house_name}: ${house_data}')
	}
}
