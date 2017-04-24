--[[

	PointShop3 MySQL Adapter by _Undefined
	
	Usage:
	
		First, make sure you have the MySQLOO module installed from:
			http://www.facepunch.com/showthread.php?t=1220537
			Installation instructions are in that thread.
	
		Then configure your MySQL details below and import the following tables into your database:

        DROP TABLE IF EXISTS `pointshop3_data`;
        CREATE TABLE `pointshop3_data` (
         `uniqueid` varchar(30) NOT NULL,
         `points` int(32) NOT NULL,
         `items` text NOT NULL,
         PRIMARY KEY (`uniqueid`)
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1
		
		MAKE SURE YOU ALLOW REMOTE ACCESS TO YOUR DATABASE FROM YOUR GMOD SERVERS IP ADDRESS.
		
		If you're upgrading from the old version, run the following SQL before starting your server and then remove the old tables (pointshop3_points and pointshop3_items):
		
			INSERT INTO `pointshop3_data` SELECT `pointshop3_points`.`uniqueid`, `points`, `items` FROM `pointshop3_points` INNER JOIN `pointshop3_items` ON `pointshop3_items`.`uniqueid` = `pointshop3_points`.`uniqueid`
		
		Once configured, change PS.Config.DataProvider = 'pdata' to PS.Config.DataProvider = 'mysql' in pointshop3's sh_config.lua.
	
]]--

-- config, change these to match your setup

local mysql_hostname = 'localhost' -- Your MySQL server address.
local mysql_username = 'root' -- Your MySQL username.
local mysql_password = '' -- Your MySQL password.
local mysql_database = 'pointshop3' -- Your MySQL database.
local mysql_port = 3306 -- Your MySQL port. Most likely is 3306.

-- end config, don't change anything below unless you know what you're doing

require('mysqloo')

local db = mysqloo.connect(mysql_hostname, mysql_username, mysql_password, mysql_database, mysql_port)

function db:onConnected()
    MsgN('PointShop3 MySQL: Connected!')
end

function db:onConnectionFailed(err)
    MsgN('PointShop3 MySQL: Connection Failed, please check your settings: ' .. err)
end

db:connect()

function PROVIDER:GetData(ply, callback)
    local qs = [[
    SELECT *
    FROM `pointshop3_data`
    WHERE uniqueid = '%s'
    ]]
    qs = string.format(qs, ply:UniqueID())
    local q = db:query(qs)
     
    function q:onSuccess(data)
        if #data > 0 then
            local row = data[1]
         
            local points = row.points or 0
            local items = util.JSONToTable(row.items or '{}')
 
            callback(points, items)
        else
            callback(0, {})
        end
    end
     
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Re-connection to database server failed.")
            callback(0, {})
            return
            end
        end
        MsgN('PointShop3 MySQL: Query Failed: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function PROVIDER:SetPoints(ply, points)
    local qs = [[
    INSERT INTO `pointshop3_data` (uniqueid, points, items)
    VALUES ('%s', '%s', '[]')
    ON DUPLICATE KEY UPDATE 
        points = VALUES(points)
    ]]
    qs = string.format(qs, ply:UniqueID(), points or 0)
    local q = db:query(qs)
     
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Re-connection to database server failed.")
            return
            end
        end
        MsgN('PointShop3 MySQL: Query Failed: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function PROVIDER:GivePoints(ply, points)
    local qs = [[
    INSERT INTO `pointshop3_data` (uniqueid, points, items)
    VALUES ('%s', '%s', '[]')
    ON DUPLICATE KEY UPDATE 
        points = points + VALUES(points)
    ]]
    qs = string.format(qs, ply:UniqueID(), points or 0)
    local q = db:query(qs)
     
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Re-connection to database server failed.")
            return
            end
        end
        MsgN('PointShop3 MySQL: Query Failed: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function PROVIDER:TakePoints(ply, points)
    local qs = [[
    INSERT INTO `pointshop3_data` (uniqueid, points, items)
    VALUES ('%s', '%s', '[]')
    ON DUPLICATE KEY UPDATE 
        points = points - VALUES(points)
    ]]
    qs = string.format(qs, ply:UniqueID(), points or 0)
    local q = db:query(qs)
     
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Re-connection to database server failed.")
            return
            end
        end
        MsgN('PointShop3 MySQL: Query Failed: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function PROVIDER:SaveItem(ply, item_id, data)
    self:GiveItem(ply, item_id, data)
end

function PROVIDER:GiveItem(ply, item_id, data)
    local tmp = table.Copy(ply.PS_Items)
    tmp[item_id] = data

    local qs = [[
    INSERT INTO `pointshop3_data` (uniqueid, points, items)
    VALUES ('%s', '0', '%s')
    ON DUPLICATE KEY UPDATE 
        items = VALUES(items)
    ]]
    qs = string.format(qs, ply:UniqueID(), db:escape(util.TableToJSON(tmp)))
    local q = db:query(qs)
     
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Re-connection to database server failed.")
            return
            end
        end
        MsgN('PointShop3 MySQL: Query Failed: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end

function PROVIDER:TakeItem(ply, item_id)
    local tmp = table.Copy(ply.PS_Items)
    tmp[item_id] = nil

    local qs = [[
    INSERT INTO `pointshop3_data` (uniqueid, points, items)
    VALUES ('%s', '0', '%s')
    ON DUPLICATE KEY UPDATE 
        items = VALUES(items)
    ]]
    qs = string.format(qs, ply:UniqueID(), db:escape(util.TableToJSON(tmp)))
    local q = db:query(qs)
     
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Re-connection to database server failed.")
            return
            end
        end
        MsgN('PointShop3 MySQL: Query Failed: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end
 
function PROVIDER:SetData(ply, points, items)
    local qs = [[
    INSERT INTO `pointshop3_data` (uniqueid, points, items)
    VALUES ('%s', '%s', '%s')
    ON DUPLICATE KEY UPDATE 
        points = VALUES(points),
        items = VALUES(items)
    ]]
    qs = string.format(qs, ply:UniqueID(), points or 0, db:escape(util.TableToJSON(items)))
    local q = db:query(qs)
     
    function q:onError(err, sql)
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            db:connect()
            db:wait()
        if db:status() ~= mysqloo.DATABASE_CONNECTED then
            ErrorNoHalt("Re-connection to database server failed.")
            return
            end
        end
        MsgN('PointShop3 MySQL: Query Failed: ' .. err .. ' (' .. sql .. ')')
        q:start()
    end
     
    q:start()
end
