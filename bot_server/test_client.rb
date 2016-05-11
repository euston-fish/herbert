require 'drb/drb'

SERVER_URI = "druby://localhost:3474"

DRb.start_service

thing_server = DRbObject.new_with_uri(SERVER_URI)
thing_server.print_something "Hello world"