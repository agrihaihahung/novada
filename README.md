# NOVADA – Smart Factory Management

Ứng dụng quản trị xưởng sản xuất nhôm thanh, gia công cửa nhôm và sản phẩm nhôm kính. Đây là dự án mới, độc lập, không kế thừa WINOVA.

## Giai đoạn đã khởi tạo
- Dashboard tổng quan, KPI tính từ dữ liệu đang tải.
- Quản lý đơn hàng: danh sách, lọc trạng thái, tạo mới.
- Danh mục vật tư: thêm mới, cảnh báo tồn tối thiểu.
- Kho: phiếu nhập/xuất và kiểm tra tồn trước khi xuất.
- Đăng nhập Supabase Auth khi cấu hình backend.
- SQL schema có ràng buộc dữ liệu, giao dịch kho và trigger cập nhật tồn.
- Những module chưa triển khai được đánh dấu rõ, không giả lập là đã hoạt động.

## Chạy local
Yêu cầu Node.js 20+.

```bash
npm install
cp .env.example .env.local
npm run dev
```

Nếu chưa cấu hình Supabase, app chạy chế độ xem thử bằng dữ liệu trong bộ nhớ (không phải dữ liệu thật, không đồng bộ và sẽ mất khi tải lại trang). Để chạy vận hành, cấu hình Supabase theo hướng dẫn bên dưới.

## Kết nối Supabase
1. Tạo một project Supabase mới.
2. Mở SQL Editor và chạy toàn bộ `supabase/schema.sql`.
3. Trong Authentication, tạo user quản trị ban đầu.
4. Copy Project URL và anon/public key vào `.env.local`:

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

5. Khởi động lại `npm run dev` và đăng nhập bằng user vừa tạo.

**Bảo mật:** Không đưa `service_role` key vào frontend. Bản Phase 1 đang áp dụng quyền truy cập cho người dùng đã xác thực; phân quyền chi tiết theo vai trò và module là hạng mục bắt buộc cần hoàn thiện trước khi triển khai production.

## Build

```bash
npm run build
npm run preview
```

## Cấu trúc

```text
src/
  App.tsx              # Shell, dashboard và các màn hình Phase 1
  styles.css           # UI responsive
  lib/supabase.ts      # Kết nối Supabase
supabase/
  schema.sql           # Database + constraints + inventory trigger + RLS
public/
  novada-logo.png
```

## Trạng thái minh bạch
- Đơn hàng, vật tư, nhập/xuất kho: thao tác CRUD cơ bản đã có trong giao diện; chế độ Supabase sẽ ghi vào database.
- Local preview: dữ liệu mẫu chỉ để kiểm thử giao diện, không phải nguồn dữ liệu sản xuất.
- Kế hoạch, lệnh sản xuất, công đoạn, máy móc, nhân sự, QC, giao hàng, giá thành, báo cáo nâng cao: chưa triển khai nghiệp vụ.
- Chưa triển khai phân quyền theo từng chức năng, audit log đầy đủ, backup/restore, import/export Excel/PDF và đồng bộ realtime.

## NOVADA Phase 2 – Kế hoạch sản xuất (xưởng gia công cửa nhôm)

### Chức năng đã bổ sung
- Tạo kế hoạch sản xuất và liên kết với đơn hàng chưa hoàn thành.
- Lưu mã kế hoạch, ngày dự kiến, số lượng, độ ưu tiên, ghi chú.
- Theo dõi trạng thái: Chờ triển khai, Đang thực hiện, Tạm dừng, Hoàn thành, Đã hủy.
- Thống kê nhanh số kế hoạch theo trạng thái và tìm kiếm theo mã kế hoạch/đơn hàng/khách hàng.
- Hiển thị quy trình tham chiếu: tiếp nhận bản vẽ → bóc tách vật tư → cắt nhôm → phay/khoan → ép góc/lắp ráp → lắp kính/phụ kiện → QC → đóng gói/bàn giao.

### Cài đặt Supabase Phase 2
1. Mở Supabase → SQL Editor → New query.
2. Mở và chạy toàn bộ file `supabase/phase2_planning.sql`.
3. Khởi động lại ứng dụng (`npm run dev`) và đăng nhập lại nếu cần.
4. Vào menu **Kế hoạch sản xuất** để tạo kế hoạch từ đơn hàng.

### Lưu ý
- File migration Phase 2 không thay đổi bảng orders, materials hoặc inventory_transactions.
- Kế hoạch được lưu vào bảng mới `production_plans`.
- Nếu đang dùng Local Preview (chưa cấu hình Supabase), kế hoạch chỉ tồn tại trong state của phiên trình duyệt.
- Bản này mới triển khai lập kế hoạch và theo dõi trạng thái tổng thể. Phân công tổ/máy, định mức bóc tách, tiến độ theo từng công đoạn, QC và giao hàng sẽ là các bước tiếp theo.
- Không đưa `.env.local`, service-role key hoặc `node_modules` vào source ZIP khi chia sẻ.

## NOVADA Phase 2.1 – Quản lý sản xuất

Bổ sung module phát hành lệnh sản xuất từ kế hoạch và cập nhật tiến độ gia công cửa nhôm.

### Cài đặt bổ sung Supabase
1. Mở Supabase → SQL Editor.
2. Chạy toàn bộ file `supabase/phase2_1_production.sql` sau khi đã chạy `phase2_planning.sql`.
3. Khởi động lại ứng dụng.

### Luồng sử dụng
1. Tạo kế hoạch trong **Kế hoạch sản xuất**.
2. Mở **Quản lý sản xuất**, chọn kế hoạch và tạo lệnh sản xuất.
3. Cập nhật công đoạn hiện tại.
4. Nhập số lượng đạt và lỗi lũy kế; tổng hai số không được vượt số lượng kế hoạch.
5. Theo dõi tiến độ và trạng thái lệnh.

Bản này ghi nhận sản lượng lũy kế ở cấp lệnh sản xuất. Chưa phải phiếu công đoạn độc lập; phân công máy/tổ, tiêu hao vật tư, QC chi tiết và truy xuất từng lần cập nhật sẽ triển khai ở các bước tiếp theo.
