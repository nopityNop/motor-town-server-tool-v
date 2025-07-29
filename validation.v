module main

import strconv

pub fn validate_instance_name(name string) ! {
	if name == '' {
		return error('instance name cannot be empty')
	}
	if name.len > 72 {
		return error('instance name cannot exceed 72 characters')
	}
	
	for i, c in name {
		if !((c >= `a` && c <= `z`) || (c >= `0` && c <= `9`) || c == `_` || c == `-`) {
			return error('instance name can only contain lowercase letters (a-z), numbers (0-9), hyphens (-), and underscores (_). Invalid character at position ${i + 1}: ${c.ascii_str()}')
		}
	}
}

pub fn validate_ip(ip string) ! {
	if ip == '' {
		return error('IP cannot be empty')
	}
	
	parts := ip.split('.')
	if parts.len != 4 {
		return error('IP address must have exactly 4 parts separated by dots')
	}
	
	for i, part in parts {
		num := strconv.atoi(part) or {
			return error('IP part ${i + 1} is not a valid number: ${part}')
		}
		if num < 0 || num > 255 {
			return error('IP part ${i + 1} must be between 0 and 255, got: ${num}')
		}
	}
}

pub fn validate_port(port_str string) ! {
	if port_str == '' {
		return error('port cannot be empty')
	}
	
	port := strconv.atoi(port_str) or {
		return error('port must be a number: ${port_str}')
	}
	
	if port < 0 || port > 65535 {
		return error('port must be between 0 and 65535, got: ${port}')
	}
}

pub fn validate_password(password string) ! {
	if password == '' {
		return error('password cannot be empty')
	}
	if password.len > 72 {
		return error('password cannot exceed 72 characters')
	}
}

pub fn mask_password(password string) string {
	if password.len <= 3 {
		return '*'.repeat(password.len)
	}
	return password[..2] + '*'.repeat(password.len - 2)
} 