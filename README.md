# ESX Whitelist

A simple whitelist resource for FiveM servers running the **ESX Framework**. This script restricts server access to approved players based on their identifier (Steam, Discord, License, etc.), stored and managed via a MySQL database.

## Features

- Player whitelist check on connect (deferral-based)
- Whitelist data stored in MySQL (`database.sql`)
- Configurable messages and settings (`config.lua`)
- Client-side notifications/handling (`client.lua`)
- Server-side identifier validation and database queries (`server.lua`)
- Support for external integrations (`integrations/`)

## Requirements

- [FiveM Server (FXServer)](https://fivem.net/)
- [ESX Framework](https://github.com/esx-framework/esx-legacy)
- A MySQL database with [`oxmysql`](https://github.com/overextended/oxmysql) (or compatible MySQL resource)

## Installation

1. Download or clone this repository into your server's `resources` folder:
   ```bash
   git clone https://github.com/amirragzon3/esx-whitelist.git
   ```

2. Import `database.sql` into your server's database.

3. Add the resource to your `server.cfg`:
   ```cfg
   ensure esx-whitelist
   ```

4. Configure the script by editing `config.lua` to match your needs (messages, identifier type, admin list, etc.).

5. Restart your server.

## Configuration

All settings can be adjusted in `config.lua`, including:

- Whitelist enable/disable toggle
- Custom kick/deferral messages
- Identifier type used for whitelist checks
- Database table/column names (if customized)

## File Structure

| File | Description |
|------|-------------|
| `fxmanifest.lua` | Resource manifest/metadata |
| `config.lua` | Configuration options |
| `client.lua` | Client-side logic |
| `server.lua` | Server-side whitelist checks and database queries |
| `database.sql` | SQL table structure for the whitelist |
| `integrations/` | Optional integrations with other systems |

## Usage

Add a player's identifier to the whitelist table in your database to grant them access. Players not present in the whitelist will be denied connection with the configured message.

## License

This project is provided as-is. Check the repository for license details, or contact the author for usage permissions.

## Support

For issues or questions, please open an [Issue](https://github.com/amirragzon3/esx-whitelist/issues) on the GitHub repository.
