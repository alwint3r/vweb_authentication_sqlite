module main

import vweb
import json
import sqlite

struct App {
	vweb.Context
mut:
	db sqlite.DB
}

struct User {
	id  int [primary; sql: serial]
	username string [unique]
	password string
}

fn main() {
	mut db := sqlite.connect('database.db') or { panic(err) }
	db.synchronization_mode(sqlite.SyncMode.off)
	db.journal_mode(sqlite.JournalMode.memory)

	defer { db.close() or { panic(err) } }

	sql db {
		create table User
	}

	existing_user := sql db {
		select from User where username == 'winter'
	}

	if existing_user.len < 1 {
		new_user := User{
			username: "winter"
			password: "password"
		}

		sql db {
			insert new_user into User
		}
	}

	vweb.run(&App{db: db}, 8080)
}

pub fn (mut app App) index() vweb.Result {
	return app.json({
		"message": "hello world!",
	})
}

[post]
pub fn (mut app App) login() vweb.Result {
	req := app.req
	body := json.decode(User, req.data) or {
		app.set_status(400, "Bad Request")
		return app.json({ "error": "Bad request" })
	}

	username := body.username
	password := body.password

	mut result := sql app.db {
		select from User where username == username
	}

	if result.len < 1 { 
		app.set_status(401, "Unauthorized")
		return app.json({ "error": "Unauthorized" })
	}

	user := result.pop()

	if user.password != password {
		app.set_status(401, "Unauthorized")
		return app.json({ "error": "Unauthorized" })
	}

	return app.json({
		"message": "ok"
	})
}
