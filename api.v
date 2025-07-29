module main

import os
import json

fn make_get_request(instance Instance, endpoint string, extra_params map[string]string) !APIResponse {
	mut url := 'http://${instance.ip}:${instance.port}${endpoint}?password=${instance.password}'
	
	if extra_params.len > 0 {
		for key, value in extra_params {
			url += '&${key}=${value}'
		}
	}
	
	result := os.execute('curl -s -X GET "${url}"')
	if result.exit_code != 0 {
		return error('curl failed with exit code ${result.exit_code}: ${result.output}')
	}
	
	resp_body := result.output.trim_space()
	if resp_body == '' {
		return error('empty response from server')
	}
	
	api_resp := json.decode(APIResponse, resp_body) or {
		return error('failed to decode response: ${err}. Response: ${resp_body[0..100]}...')
	}
	
	if !api_resp.succeeded {
		return error('API call failed: ${api_resp.message}')
	}
	
	return api_resp
}

fn make_post_request(instance Instance, endpoint string, extra_params map[string]string) !APIResponse {
	mut url := 'http://${instance.ip}:${instance.port}${endpoint}?password=${instance.password}'
	
	if extra_params.len > 0 {
		for key, value in extra_params {
			url += '&${key}=${value.replace(' ', '%20')}'
		}
	}
	
	mut curl_cmd := 'curl -s -X POST -H "Content-Length: 0" "${url}"'
	
	result := os.execute(curl_cmd)
	
	if result.exit_code != 0 {
		return error('curl failed with exit code ${result.exit_code}: ${result.output}')
	}
	
	resp_body := result.output.trim_space()
	if resp_body == '' {
		return error('empty response from server')
	}
	
	api_resp := json.decode(APIResponse, resp_body) or {
		return error('failed to decode response: ${err}. Response: ${resp_body[0..100]}...')
	}
	
	if !api_resp.succeeded {
		return error('API call failed: ${api_resp.message}')
	}
	
	return api_resp
}

pub fn send_chat_message(instance Instance, message string) !APIResponse {
	if message == '' {
		return error('message cannot be empty')
	}
	
	mut params := map[string]string{}
	params['message'] = message
	return make_post_request(instance, '/chat', params)
}

pub fn get_player_count(instance Instance) !APIResponse {
	empty_params := map[string]string{}
	return make_get_request(instance, '/player/count', empty_params)
}

pub fn get_player_list(instance Instance) !APIResponse {
	empty_params := map[string]string{}
	return make_get_request(instance, '/player/list', empty_params)
}

pub fn get_ban_list(instance Instance) !APIResponse {
	empty_params := map[string]string{}
	return make_get_request(instance, '/player/banlist', empty_params)
}

pub fn get_version(instance Instance) !APIResponse {
	empty_params := map[string]string{}
	return make_get_request(instance, '/version', empty_params)
}

pub fn get_housing_list(instance Instance) !APIResponse {
	empty_params := map[string]string{}
	return make_get_request(instance, '/housing/list', empty_params)
}

pub fn kick_player(instance Instance, unique_id string) !APIResponse {
	if unique_id == '' {
		return error('unique_id cannot be empty')
	}
	
	mut params := map[string]string{}
	params['unique_id'] = unique_id
	return make_post_request(instance, '/player/kick', params)
}

pub fn ban_player(instance Instance, unique_id string, hours int, reason string) !APIResponse {
	if unique_id == '' {
		return error('unique_id cannot be empty')
	}
	
	mut params := map[string]string{}
	params['unique_id'] = unique_id
	
	if hours > 0 {
		params['hours'] = hours.str()
	}
	
	if reason != '' {
		params['reason'] = reason
	}
	
	return make_post_request(instance, '/player/ban', params)
}

pub fn unban_player(instance Instance, unique_id string) !APIResponse {
	if unique_id == '' {
		return error('unique_id cannot be empty')
	}
	
	mut params := map[string]string{}
	params['unique_id'] = unique_id
	return make_post_request(instance, '/player/unban', params)
} 