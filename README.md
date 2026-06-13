<div align="center">

# 🛡️ ESX Whitelist

**A lightweight, database-driven whitelist system for FiveM servers running the ESX Framework.**

[![Lua](https://img.shields.io/badge/Lua-100%25-blue.svg)](https://github.com/amirragzon3/esx-whitelist)
[![Framework](https://img.shields.io/badge/Framework-ESX-orange.svg)](https://github.com/esx-framework)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 📖 Overview

**ESX Whitelist** lets server owners restrict access to their FiveM server, allowing only approved players to connect. Whitelist entries are stored in a MySQL database, checked on player connection via a deferral, and fully configurable to match your server's branding and rules.

---

## ✨ Features

- ✅ **Connection-time whitelist check** using FiveM deferrals
- 🗄️ **MySQL-backed storage** for whitelist entries
- ⚙️ **Fully configurable** messages, identifiers, and behavior
- 🧩 **Integration support** for external systems
- 🚀 **Lightweight & optimized** — minimal resource usage
- 🔐 Built for **ESX Framework** servers

---

## 📋 Requirements

| Dependency | Link |
|---|---|
| FXServer | [FiveM Server](https://fivem.net/) |
| ESX Framework | [esx-framework/esx-legacy](https://github.com/esx-framework/esx-legacy) |
| MySQL Resource | [oxmysql](https://github.com/overextended/oxmysql) |

---

## 🚀 Installation

**1. Clone the repository** into your server's `resources` folder:

```bash
git clone https://github.com/amirragzon3/esx-whitelist.git
```

**2. Import the database schema** found in `database.sql` into your MySQL database.

**3. Add the resource** to your `server.cfg`:

```cfg
ensure esx-whitelist
```

**4. Configure** the script to your liking by editing `config.lua`.

**5. Restart your server.** 🎉

---

## ⚙️ Configuration

All customizable options live in **`config.lua`**, including:

- 🔄 Enable / disable the whitelist system
- 💬 Custom connection / kick / deferral messages
- 🆔 Identifier type used for whitelist checks (Steam, License, Discord, etc.)
- 🗃️ Database table & column names (if customized)

---

## 📂 File Structure

```
esx-whitelist/
├── client.lua          # Client-side logic
├── server.lua          # Server-side whitelist validation & DB queries
├── config.lua          # Configuration options
├── database.sql        # Database schema for the whitelist table
├── fxmanifest.lua       # Resource manifest
└── integrations/        # Optional third-party integrations
```

---

## 🧑‍💻 Usage

To grant a player access, add their identifier to the whitelist table in your database. Players whose identifiers are **not** present will be rejected on connect with the message defined in `config.lua`.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](https://github.com/amirragzon3/esx-whitelist/issues) or submit a pull request.

---

## 📄 License

This project is open-source. See the repository for license details.

---

<div align="center">

Made with ❤️ for the FiveM community

</div>
