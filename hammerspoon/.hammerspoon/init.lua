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
-- HÀM CHỨA CHUỖI HÀNH ĐỘNG TỰ ĐỘNG THEO DANH SÁCH
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
-- 2. BẮT ĐẦU VÒNG LẶP VÔ HẠN (Bấm Cmd + Option + Ctrl + Y)
-- ==========================================
hs.hotkey.bind({ "cmd", "option", "ctrl" }, "Y", function()
	if loopTimer or reloadTimer then
		hs.alert.show("Vòng lặp đang chạy rồi!")
		return
	end

	hs.alert.show(
		string.format("🚀 BẮT ĐẦU CHẠY CHUỖI %d CLICK (Sẽ reload mỗi 5 phút)", #targetYList),
		2
	)

	isReloading = false

	-- Kích hoạt vòng lặp chính
	runActionSequence()

	-- Kích hoạt vòng lặp reload mỗi 5 phút (300 giây)
	reloadTimer = hs.timer.doEvery(reloadInterval, doReloadAndClick)
end)

-- ==========================================
-- 3. DỪNG VÒNG LẶP (Bấm Cmd + Option + Ctrl + S)
-- ==========================================
hs.hotkey.bind({ "cmd", "option", "ctrl" }, "S", function()
	-- Dừng vòng lặp click chính
	if loopTimer then
		loopTimer:stop()
		loopTimer = nil
	end

	-- Dừng bộ đếm thời gian 5 phút
	if reloadTimer then
		reloadTimer:stop()
		reloadTimer = nil
	end

	isReloading = false
	hs.alert.show("🛑 ĐÃ DỪNG TẤT CẢ VÒNG LẶP!", 1.5)
end)
