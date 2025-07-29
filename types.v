module main

pub struct Instance {
pub mut:
	ip       string
	port     int
	password string
}

pub struct APIResponse {
pub mut:
	data      map[string]string @[json: data]
	message   string            @[json: message]
	succeeded bool              @[json: succeeded]
	code      int               @[json: code]
}

pub struct Config {
pub mut:
	instances map[string]Instance @[json: instances]
}

pub struct Player {
pub mut:
	name      string @[json: name]
	unique_id string @[json: unique_id]
}

pub struct PlayerCountData {
pub mut:
	num_players int @[json: num_players]
}

pub struct VersionData {
pub mut:
	version string @[json: version]
}

pub struct HousingData {
pub mut:
	owner_unique_id string @[json: owner_unique_id]
	expire_time     string @[json: expire_time]
} 