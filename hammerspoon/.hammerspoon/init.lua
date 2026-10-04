-- Biến toàn cục để quản lý trạng thái
local loopTimer = nil
local reloadTimer = nil
local isReloading = false -- Cờ kiểm soát việc tạm dừng click khi đang reload

-- Khởi tạo trình tạo số ngẫu nhiên
math.randomseed(os.time())

-- =========================================================================
-- KHU VỰC CẤU HÌNH (Bạn có thể thoải mái sửa đổi ở đây)
-- =========================================================================
-- Vùng ngẫu nhiên cho trục X
local minX = 600
local maxX = 800

-- DANH SÁCH CÁC TRỤC Y: Muốn click thêm chỗ nào, bạn chỉ cần phẩy (,) rồi thêm số vào đây
local targetYList = { 851, 789, 796, 891, 905, 844 }

-- Khoảng trễ ngẫu nhiên giữa các hành động click/phím (tính bằng micro-giây: 40000 = 0.04s)
local minActionDelay = 40000
local maxActionDelay = 80000

-- Khoảng trễ ngẫu nhiên giữa mỗi VÒNG LẶP chính (tính bằng giây)
local minLoopDelay = 0.1
local maxLoopDelay = 0.3

-- CẤU HÌNH TÁC VỤ 5 PHÚT (RELOAD & CLICK)
local reloadInterval = 120 -- 5 phút = 300 giây
local browserReloadButtonPos = { x = 93, y = 97 } -- Toạ độ nút Reload trên trình duyệt
local targetReloadPos = { x = 699, y = 565 }
local pageLoadWaitTime = 5 -- Thời gian chờ (giây) để trang tải xong trước khi click

-- CHẾ ĐỘ CHẠY: "A" = Block A (chuỗi click cũ + reload), "B" = Block B (tap, chờ, space)
-- Đổi chế độ bằng Cmd + Option + Ctrl + M
local currentMode = "A"

-- CẤU HÌNH BLOCK B
local blockBTapPos = { x = 398, y = 827 } -- Toạ độ tap
local blockBMinWait = 5 -- Thời gian chờ tối thiểu (giây) trước khi nhấn Space
local blockBMaxWait = 10 -- Thời gian chờ tối đa (giây) trước khi nhấn Space
-- =========================================================================

-- ==========================================
-- 1. LẤY TOẠ ĐỘ X, Y (Bấm Cmd + Option + Ctrl + C)
-- ==========================================
hs.hotkey.bind({ "cmd", "option", "ctrl" }, "C", function()
	local mousePos = hs.mouse.absolutePosition()
	local x = math.floor(mousePos.x)
	local y = math.floor(mousePos.y)
	hs.alert.show(string.format("Tọa độ của bạn: x = %d, y = %d", x, y), 2.5)
end)

-- ==========================================
-- HÀM THỰC HIỆN RELOAD TRANG VÀ CLICK MỖI 5 PHÚT
-- ==========================================
local function doReloadAndClick()
	isReloading = true -- Bật cờ khóa vòng lặp chính
	hs.alert.show("🔄 Đang click nút tải lại trang...", 2)

	-- Di chuyển và click vào nút Reload của trình duyệt
	hs.mouse.setAbsolutePosition(browserReloadButtonPos)
	hs.eventtap.leftClick(browserReloadButtonPos)

	-- Đợi trang web tải xong rồi mới click vào toạ độ xác nhận
	hs.timer.doAfter(pageLoadWaitTime, function()
		-- Di chuyển chuột và click vào điểm yêu cầu
		hs.mouse.setAbsolutePosition(targetReloadPos)
		hs.eventtap.leftClick(targetReloadPos)
		hs.alert.show("✅ Đã click xác nhận sau reload!", 2)

		isReloading = false -- Tắt cờ, cho phép vòng lặp chính chạy tiếp
	end)
end

-- ==========================================
-- BLOCK A: CHUỖI HÀNH ĐỘNG TỰ ĐỘNG THEO DANH SÁCH
-- ==========================================
local function runActionSequence()
	-- NẾU ĐANG RELOAD TRANG (Mỗi 5 phút), TẠM DỪNG VIỆC CLICK LUNG TUNG
	if isReloading then
		-- Chờ 2 giây rồi tự gọi lại để kiểm tra xem đã reload xong chưa
		loopTimer = hs.timer.doAfter(2, runActionSequence)
		return
	end

	-- Lặp qua từng trục Y có trong danh sách targetYList
	for _, currentY in ipairs(targetYList) do
		-- Tạo X ngẫu nhiên cho mỗi điểm click
		local randomX = math.random(minX, maxX)
		local dynamicPos = { x = randomX, y = currentY }

		-- Di chuyển và thực hiện click
		hs.mouse.setAbsolutePosition(dynamicPos)
		hs.eventtap.leftClick(dynamicPos)

		-- Chờ một khoảng ngẫu nhiên siêu ngắn giữa các lượt click
		hs.timer.usleep(math.random(minActionDelay, maxActionDelay))
	end

	-- Sau khi click hết tất cả các điểm Y, thực hiện nhấn phím Mũi tên phải
	hs.eventtap.keyStroke({}, "right")

	-- Tính toán thời gian nghỉ ngẫu nhiên trước khi lặp lại toàn bộ quy trình
	local randomDelay = minLoopDelay + (math.random() * (maxLoopDelay - minLoopDelay))

	-- Lập lịch chạy lại chính hàm này
	loopTimer = hs.timer.doAfter(randomDelay, runActionSequence)
end

-- ==========================================
-- BLOCK B: TAP -> CHỜ 5-10s -> SPACE -> CHỜ 1s -> MŨI TÊN PHẢI -> CHỜ 1s -> LẶP LẠI
-- ==========================================
local function runBlockBSequence()
	-- Tap vào toạ độ
	hs.mouse.setAbsolutePosition(blockBTapPos)
	hs.eventtap.leftClick(blockBTapPos)

	-- Chờ ngẫu nhiên 5-10 giây rồi nhấn Space
	local waitTime = blockBMinWait + (math.random() * (blockBMaxWait - blockBMinWait))
	loopTimer = hs.timer.doAfter(waitTime, function()
		hs.eventtap.keyStroke({}, "space")

		-- Chờ 1 giây rồi nhấn phím Mũi tên phải
		loopTimer = hs.timer.doAfter(1, function()
			hs.eventtap.keyStroke({}, "right")

			-- Chờ 1 giây rồi lặp lại toàn bộ quy trình
			loopTimer = hs.timer.doAfter(1, runBlockBSequence)
		end)
	end)
end

-- ==========================================
-- HÀM BẮT ĐẦU / DỪNG THEO CHẾ ĐỘ HIỆN TẠI
-- ==========================================
local function stopAll()
	if loopTimer then
		loopTimer:stop()
		loopTimer = nil
	end

	if reloadTimer then
		reloadTimer:stop()
		reloadTimer = nil
	end

	isReloading = false
end

local function startCurrentMode()
	isReloading = false

	if currentMode == "A" then
		hs.alert.show(
			string.format("🚀 BLOCK A: BẮT ĐẦU CHẠY CHUỖI %d CLICK (Sẽ reload mỗi 5 phút)", #targetYList),
			2
		)
		-- Kích hoạt vòng lặp chính
		runActionSequence()
		-- Kích hoạt vòng lặp reload định kỳ
		reloadTimer = hs.timer.doEvery(reloadInterval, doReloadAndClick)
	else
		hs.alert.show(
			string.format("🚀 BLOCK B: TAP (%d, %d) -> CHỜ %d-%ds -> SPACE -> →", blockBTapPos.x, blockBTapPos.y, blockBMinWait, blockBMaxWait),
			2
		)
		runBlockBSequence()
	end
end

-- ==========================================
-- 2. BẮT ĐẦU VÒNG LẶP VÔ HẠN THEO CHẾ ĐỘ HIỆN TẠI (Bấm Cmd + Option + Ctrl + Y)
-- ==========================================
hs.hotkey.bind({ "cmd", "option", "ctrl" }, "Y", function()
	if loopTimer or reloadTimer then
		hs.alert.show("Vòng lặp đang chạy rồi!")
		return
	end

	startCurrentMode()
end)

-- ==========================================
-- 3. DỪNG VÒNG LẶP (Bấm Cmd + Option + Ctrl + S)
-- ==========================================
hs.hotkey.bind({ "cmd", "option", "ctrl" }, "S", function()
	stopAll()
	hs.alert.show("🛑 ĐÃ DỪNG TẤT CẢ VÒNG LẶP!", 1.5)
end)

-- ==========================================
-- 4. ĐỔI BLOCK A <-> B (Bấm Cmd + Option + Ctrl + M)
-- Nếu đang chạy thì tự động dừng block cũ và chạy block mới
-- ==========================================
hs.hotkey.bind({ "cmd", "option", "ctrl" }, "M", function()
	local wasRunning = (loopTimer ~= nil) or (reloadTimer ~= nil)
	stopAll()

	currentMode = (currentMode == "A") and "B" or "A"
	hs.alert.show("🔀 Đã chuyển sang BLOCK " .. currentMode, 1.5)

	if wasRunning then
		startCurrentMode()
	end
end)
