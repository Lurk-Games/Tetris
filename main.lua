-- main.lua

-- Constants
local BLOCK_SIZE = 30
local BOARD_WIDTH = 10
local BOARD_HEIGHT = 20
local MOVE_DOWN_INTERVAL = 0.5
local MOVE_INTERVAL = 0.1
local ROTATE_INTERVAL = 0.2

-- Game state
local board = {}
local currentBlock = nil
local moveDownTimer = 0
local moveTimer = 0
local rotateTimer = 0
local score = 0
local gameOver = false

-- Shapes definition
local shapes = {
    { {1, 1, 1, 1} }, -- I
    { {1, 1}, {1, 1} }, -- O
    { {0, 1, 1}, {1, 1, 0} }, -- S
    { {1, 1, 0}, {0, 1, 1} }, -- Z
    { {1, 0, 0}, {1, 1, 1} }, -- J
    { {0, 0, 1}, {1, 1, 1} }, -- L
    { {0, 1, 0}, {1, 1, 1} } -- T
}

-- Color definitions
local colors = {
    {1, 0, 0}, -- Red
    {0, 1, 0}, -- Green
    {0, 0, 1}, -- Blue
    {1, 1, 0}, -- Yellow
    {1, 0, 1}, -- Magenta
    {0, 1, 1}, -- Cyan
    {1, 0.5, 0} -- Orange
}

local backgroundMusic

function love.load()
    love.window.setMode(BOARD_WIDTH * BLOCK_SIZE, BOARD_HEIGHT * BLOCK_SIZE)
    initializeBoard()
    spawnNewBlock()
    backgroundMusic = love.audio.newSource("background.ogg", "stream")
    backgroundMusic:setLooping(true)
    backgroundMusic:play()
end

function love.update(dt)
    if gameOver then
        return
    end

    moveDownTimer = moveDownTimer + dt
    moveTimer = moveTimer + dt
    rotateTimer = rotateTimer + dt

    if moveDownTimer >= MOVE_DOWN_INTERVAL then
        moveDownTimer = 0
        moveCurrentBlockDown()
    end

    if moveTimer >= MOVE_INTERVAL then
        if love.keyboard.isDown("left") then
            moveCurrentBlock(-1, 0)
            moveTimer = 0
        elseif love.keyboard.isDown("right") then
            moveCurrentBlock(1, 0)
            moveTimer = 0
        elseif love.keyboard.isDown("down") then
            moveCurrentBlockDown()
            moveTimer = 0
        end
    end

    if rotateTimer >= ROTATE_INTERVAL then
        if love.keyboard.isDown("up") then
            rotateCurrentBlock()
            rotateTimer = 0
        end
    end
end

function love.draw()
    drawBoard()
    drawBlock(currentBlock)
    drawScore()
    if gameOver then
        drawGameOver()
    end
end

function initializeBoard()
    for y = 1, BOARD_HEIGHT do
        board[y] = {}
        for x = 1, BOARD_WIDTH do
            board[y][x] = {0, {1, 1, 1}} -- Empty blocks are white
        end
    end
end

function spawnNewBlock()
    local shapeIndex = math.random(#shapes)
    local shape = shapes[shapeIndex]
    local color = colors[shapeIndex]
    currentBlock = { shape = shape, color = color, x = math.floor(BOARD_WIDTH / 2) - 1, y = 1 }
    
    if not canMove(currentBlock, 0, 0) then
        gameOver = true
    end
end

function moveCurrentBlockDown()
    if not moveCurrentBlock(0, 1) then
        placeBlock(currentBlock)
        clearFullLines()
        spawnNewBlock()
    end
end

function moveCurrentBlock(dx, dy)
    if canMove(currentBlock, dx, dy) then
        currentBlock.x = currentBlock.x + dx
        currentBlock.y = currentBlock.y + dy
        return true
    end
    return false
end

function rotateCurrentBlock()
    local newShape = {}
    local shape = currentBlock.shape
    local shapeHeight = #shape
    local shapeWidth = #shape[1]

    for y = 1, shapeWidth do
        newShape[y] = {}
        for x = 1, shapeHeight do
            newShape[y][x] = shape[shapeHeight - x + 1][y]
        end
    end
    if canMove({ shape = newShape, x = currentBlock.x, y = currentBlock.y }, 0, 0) then
        currentBlock.shape = newShape
    end
end

function canMove(block, dx, dy)
    local shape = block.shape
    local newX = block.x + dx
    local newY = block.y + dy

    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] ~= 0 then
                local boardX = newX + x
                local boardY = newY + y
                if boardX < 1 or boardX > BOARD_WIDTH or boardY < 1 or boardY > BOARD_HEIGHT or (board[boardY] and board[boardY][boardX][1]) ~= 0 then
                    return false
                end
            end
        end
    end
    return true
end

function placeBlock(block)
    local shape = block.shape
    local color = block.color
    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] ~= 0 then
                local boardX = block.x + x
                local boardY = block.y + y
                if board[boardY] and board[boardY][boardX] then
                    board[boardY][boardX] = {shape[y][x], color}
                end
            end
        end
    end
end

function clearFullLines()
    local newBoard = {}
    local linesCleared = 0

    for y = 1, BOARD_HEIGHT do
        local fullLine = true
        for x = 1, BOARD_WIDTH do
            if board[y][x][1] == 0 then
                fullLine = false
                break
            end
        end
        if fullLine then
            linesCleared = linesCleared + 1
        else
            table.insert(newBoard, board[y])
        end
    end

    for i = 1, linesCleared do
        table.insert(newBoard, 1, {})
        for x = 1, BOARD_WIDTH do
            newBoard[1][x] = {0, {1, 1, 1}}
        end
    end

    board = newBoard
    score = score + (linesCleared * linesCleared * 100) -- Increase score based on the number of lines cleared with a multiplier
end

function drawBoard()
    for y = 1, BOARD_HEIGHT do
        for x = 1, BOARD_WIDTH do
            if board[y][x][1] ~= 0 then
                love.graphics.setColor(board[y][x][2])
                love.graphics.rectangle("fill", (x - 1) * BLOCK_SIZE, (y - 1) * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
            end
        end
    end
end

function drawBlock(block)
    local shape = block.shape
    local color = block.color
    love.graphics.setColor(color)
    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] ~= 0 then
                love.graphics.rectangle("fill", (block.x + x - 1) * BLOCK_SIZE, (block.y + y - 1) * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
            end
        end
    end
end

function drawScore()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
end

function drawGameOver()
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("Game Over", (BOARD_WIDTH * BLOCK_SIZE) / 2 - 50, (BOARD_HEIGHT * BLOCK_SIZE) / 2)
    love.graphics.print("Press R to Restart", (BOARD_WIDTH * BLOCK_SIZE) / 2 - 70, (BOARD_HEIGHT * BLOCK_SIZE) / 2 + 20)
end

function love.keypressed(key)
    if key == "r" and gameOver then
        restartGame()
    end
end

function restartGame()
    initializeBoard()
    spawnNewBlock()
    score = 0
    gameOver = false
end
