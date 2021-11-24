resource "time_static" "current" {}

output "current_time_epoch" {
	value = time_static.current.unix
}
