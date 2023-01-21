# register cleanup functions as needed
source shellswain.bash

load_plugins(){
	for plugin in "$@"; do
		source "plugins/$plugin" "$@"
	done
}

load_plugins "mysql" "postgres" "redis"

# -- plugins/mysql --
start_mysql(){
	echo "pretend we're starting mysql"
	event on swain:before_exit stop_mysql
}
stop_mysql(){
	echo "pretend we're stopping mysql"
}

# -- plugins/postgres --
start_postgres(){
	echo "pretend we're starting postgres"
	event on swain:before_exit stop_postgres
}
stop_postgres(){
	echo "pretend we're stopping postgres"
}

# -- plugins/redis --
start_redis(){
	echo "pretend we're starting redis"
	event on swain:before_exit stop_redis
}
stop_redis(){
	echo "pretend we're stopping redis"
}
