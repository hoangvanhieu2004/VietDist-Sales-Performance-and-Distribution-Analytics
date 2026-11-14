# Hướng dẫn dashboard Power BI

Dashboard `03_power_bi/vietdist_dashboard.pbix` có 6 trang, đọc dữ liệu từ schema `dwh` của database `vietdist_dw1`. Tài liệu này giúp dựng lại hoặc kiểm tra dashboard mà không cần mở file `.pbix`. Ý nghĩa từng cột trong Gold xem ở `docs/data_dictionary.md`. Giả định (A-xx) và hạn chế (L-xx) xem ở `docs/assumptions_log.md`.

## Các trang và yêu cầu BRD

| Trang | Báo cáo BRD | Trả lời được | Bỏ qua |
|---|---|---|---|
| Tổng quan | BR-A-01 | Doanh thu thuần so chỉ tiêu hiện hành và kế hoạch đầu năm, lọc theo vùng, nhóm, sản phẩm, nhân viên, tô màu đạt/không đạt, hàng trả, khách hàng đã mua | So cùng kỳ (L-01), dự báo cuối kỳ (L-14) |
| Chỉ tiêu | BR-A-02 | Thực tế so từng phiên bản, phiên bản áp dụng mỗi tháng, chỉ tiêu theo nhân viên và tháng, lịch sử phiên bản | Kế hoạch v3 chưa có (L-08) |
| Khách hàng & SP | BR-A-03 | Sản phẩm bán chạy, bán chậm, không bán được, Top 10/20 khách hàng và nhân viên phụ trách (A-03), khách mới, quay lại, churn (A-04) | Doanh thu trong và ngoài kỳ khuyến mãi (L-13) |
| Nhân viên | BR-A-04 | Các giai đoạn công tác theo SCD2, doanh thu từng giai đoạn, xu hướng tăng trưởng (A-27) | Lịch sử trước 2024 (L-15) |
| Kênh phân phối | BR-B-01 | Đơn hàng theo kênh và tháng, tỷ trọng kênh, Fill Rate (A-17), Top 10 nhà phân phối, nhà phân phối giảm sút (A-28), cảnh báo 30 ngày | So cùng kỳ (L-01), xem theo ngày, tuần (L-16) |
| Hiệu suất NPP | BR-B-02 | Giá trị đặt theo tháng và lũy kế năm, % so tháng trước, bảng nhiệt theo tháng, khung lịch sử cấp độ và vùng | Chỉ tiêu và % đạt (L-03), lịch sử thay đổi (L-05) |
| (không có) | BR-B-03 | | Toàn bộ: không có dữ liệu tồn kho (L-04) |
| (không có) | BR-B-04 | | Toàn bộ: Gold không có đối tượng khuyến mãi (L-13) |

## Mô hình dữ liệu

Chế độ Import. Nạp 10 đối tượng của `dwh`, đổi tên bỏ tiền tố `dwh`. Thêm bảng `_Measures` chỉ để chứa measure.

Quan hệ (một nhiều, lọc một chiều từ dim sang fact):

| Từ | Đến |
|---|---|
| `dim_date[date_key]` | `fact_sales`, `fact_returns`, `fact_targets`, `mart_sales_vs_target`, `mart_distributor_performance` |
| `dim_employees[employee_sk]` | `fact_sales`, `fact_returns`, `fact_targets`, `mart_sales_vs_target` |
| `dim_customers[customer_id]` | `fact_sales`, `fact_returns` |
| `dim_products[product_id]` | `fact_sales`, `fact_returns` |
| `dim_distributors[distributor_sk]` | `mart_distributor_performance` |

Hai thiết lập bắt buộc:

1. **Đánh dấu bảng ngày.** Chọn `dim_date`, vào Table tools, chọn Mark as date table, chọn cột `full_date` (kiểu Date). Các bảng nối qua `date_key` là số nguyên, nên nếu không đánh dấu thì `TOTALYTD` và `DATEADD` không gỡ được bộ lọc tháng, và lũy kế chỉ bằng đúng tháng đó.
2. **Lọc năm 2024 cho mọi trang.** Thêm `dim_date[year] = 2024` vào Filters on all pages. `dim_date` có 2022 đến 2026, nên nếu không lọc thì card lũy kế năm tính cho năm 2026 và trống, còn slicer Quý gộp quý của mọi năm.

## Phân quyền (Row-Level Security)

Tạo ở Modeling, Manage roles. Mỗi role là bộ lọc DAX trên bảng dim, tự lan xuống fact và mart qua quan hệ (A-29). Role tĩnh vì Gold không có email nhân viên (L-17).

| Role | Cấp bậc BRD 5.2 | `dim_employees` | `dim_distributors` |
|---|---|---|---|
| `BGD` | Ban Giám đốc | không lọc | không lọc |
| `GD_Mien_Bac` | Giám đốc Vùng | `[region] = "Miền Bắc"` | `[region] = "Miền Bắc"` |
| `GD_Mien_Trung` | Giám đốc Vùng | `[region] = "Miền Trung"` | `[region] = "Miền Trung"` |
| `GD_Mien_Nam` | Giám đốc Vùng | `[region] = "Miền Nam"` | `[region] = "Miền Nam"` |
| `TN_Team_Bac_1` | Trưởng nhóm (mẫu) | `[team] = "Team Bắc 1"` | `FALSE()` |
| `NV_EMP1004` | Nhân viên Sales (mẫu) | `[employee_id] = "EMP1004"` | `FALSE()` |
| `QLNPP_EMP1034` | Quản lý Nhà phân phối (mẫu) | `FALSE()` | `[assigned_supervisor_id] = "EMP1034"` |

Kiểm tra bằng Modeling, View as:

| Role | Doanh thu | Nhà phân phối |
|---|---|---|
| `BGD` | 139.793.210.000 | 138 NPP, giá trị đặt 167.455.562.390, cảnh báo 14 |
| `GD_Mien_Bac` | 42.856.018.800 | 50 NPP, 60.529.600.070, cảnh báo 5 |
| `GD_Mien_Trung` | 51.612.195.200 | 42 NPP, 51.557.093.360, cảnh báo 4 |
| `GD_Mien_Nam` | 45.324.996.000 | 46 NPP, 55.368.868.960, cảnh báo 5 |
| `TN_Team_Bac_1` | 14.122.590.400 | trống |
| `NV_EMP1004` | 1.263.151.600 | trống |
| `QLNPP_EMP1034` | trống | 22 NPP, 29.520.178.510, 1.375 đơn, cảnh báo 1 |

Kiểm tra lịch sử chuyển vùng: với `GD_Mien_Bac`, trang Nhân viên chỉ hiện giai đoạn Miền Bắc của Đỗ Minh An (538.183.300, tháng 1 đến 6). Với `GD_Mien_Trung`, chỉ hiện giai đoạn Miền Trung (724.968.300, tháng 7 đến 12).

## Triển khai Power BI Service

Theo BRD 5.1, có một semantic model dùng chung, và báo cáo của từng branch kết nối vào model đó thay vì tự kết nối nguồn. Các file `.pbix` nằm trong `03_power_bi/` nhưng không được commit (`*.pbix` có trong `.gitignore`), vì chúng chứa dữ liệu.

| File | Nội dung | Trên Service |
|---|---|---|
| `vietdist_dashboard.pbix` | Bản gộp: model và 6 trang. Dùng để phát triển, đúng tên file trong cây thư mục của đề bài | Không publish |
| `VietDist_Model.pbix` | 10 bảng, 14 quan hệ, `_Measures`, bảng `Top N`, 7 role. Chỉ có 1 trang Giới thiệu | Semantic model `VietDist_Model`, Promoted |
| `VietDist_BranchA.pbix` | 4 trang Branch A, Live connection vào `VietDist_Model`, không chứa dữ liệu hay measure | Report |
| `VietDist_BranchB.pbix` | 2 trang Branch B, Live connection vào `VietDist_Model` | Report |

Luồng dữ liệu (xem ở View, Lineage view trong workspace):

```
PostgreSQL (localhost, vietdist_dw1) ── On-premises data gateway ── VietDist_Model ──┬── VietDist_BranchA
                                                                                     └── VietDist_BranchB
```

### Các bước đã làm

1. **Gateway.** Cài On-premises data gateway trên máy có PostgreSQL. Trên Service, vào Manage connections and gateways, tạo kết nối `VietDist PostgreSQL`: kiểu PostgreSQL, server `localhost`, database `vietdist_dw1`, xác thực Basic, chọn **Not encrypted** (PostgreSQL trên máy không bật SSL). Server và database phải viết giống hệt trong Desktop.
2. **Model.** Từ bản gộp, lưu thành `VietDist_Model.pbix`, xóa 6 trang, publish vào workspace `VietDist Analytics`.
3. **Cài đặt model trên Service.** Ở Gateway and cloud connections, nối nguồn vào `VietDist PostgreSQL`. Không nhập ở Data source credentials, vì Service sẽ kết nối thẳng tới `localhost` mà không qua gateway, và báo "Unable to connect to the data source". Bật Scheduled refresh lúc 7:30 hằng ngày (UTC+07:00), chọn Endorsement là Promoted.
4. **Báo cáo mỏng.**
   - Từ bản gộp, lưu thành `VietDist_BranchA.pbix` và xóa 2 trang Branch B.
   - Ở Model view, xóa toàn bộ bảng.
   - Vào Get data, chọn Power BI semantic models, rồi chọn `VietDist_Model`. Tên bảng, cột và measure giống hệt nên các visual tự hiện lại.
   - Thêm lại bộ lọc `dim_date[year] = 2024` ở Filters on all pages. Bộ lọc này thuộc báo cáo nên mất khi xóa bảng.
   - Publish. Làm tương tự cho BranchB.
5. **Phân quyền.** Ở Semantic model, Security, gán email vào từng role và kiểm tra bằng Test as role. RLS chỉ áp dụng cho người có quyền **Viewer**. Admin, Member và Contributor của workspace luôn thấy toàn bộ dữ liệu.

### Kiểm tra

| Kiểm tra | Kết quả đúng |
|---|---|
| Refresh history của `VietDist_Model` | Completed |
| BranchA, trang Tổng quan | `DT thuần có chỉ tiêu` 138.594.961.100, `% Hoàn thành` 49,61% |
| BranchB, trang Kênh phân phối | `Giá trị đặt NPP` 167.455.562.390, `NPP cảnh báo 30 ngày` 14 |
| Cập nhật tại một nơi | Thêm một measure vào `VietDist_Model.pbix` rồi publish lại. Cả BranchA và BranchB đều thấy measure mới mà không phải sửa báo cáo |

### Thêm metric mới

Mở `VietDist_Model.pbix`, thêm measure vào `_Measures`, publish đè lên model cũ. Không tạo measure trong báo cáo mỏng, vì measure đó chỉ thuộc riêng báo cáo ấy và không dùng chung được. Sau đó cập nhật mục Measure bên dưới.

## Measure

Định dạng: measure tiền là Whole number, measure tỷ lệ là Percentage.

### Doanh thu và hàng trả

```dax
Doanh thu = SUM ( fact_sales[revenue_amount] )
```
```dax
Hàng trả bị trừ = SUM ( fact_returns[deducted_amount] )
```
```dax
Doanh thu thuần = [Doanh thu] - [Hàng trả bị trừ]
```
```dax
Doanh thu thuần lũy kế năm = TOTALYTD ( [Doanh thu thuần], dim_date[full_date] )
```
```dax
SL hàng trả =
CALCULATE ( SUM ( fact_returns[return_quantity] ), fact_returns[is_deducted] = TRUE () )
```
```dax
SL bán =
CALCULATE ( SUM ( fact_sales[quantity] ), fact_sales[is_delivered] = TRUE () )
```

`revenue_amount` chỉ có giá trị ở đơn `Delivered` (A-01). Hàng trả chỉ trừ phiếu `Đã xử lý` (A-02).

### Chỉ tiêu

`mart_sales_vs_target` lặp doanh thu thực tế ở mọi phiên bản của cùng một tháng, nên luôn lọc đúng một phiên bản trước khi cộng.

```dax
Chỉ tiêu hiện hành =
CALCULATE (
    SUM ( mart_sales_vs_target[target_revenue] ),
    mart_sales_vs_target[is_latest] = TRUE (),
    mart_sales_vs_target[is_active_month] = TRUE (),
    mart_sales_vs_target[target_revenue] > 0
)
```
```dax
DT thuần có chỉ tiêu =
CALCULATE (
    SUM ( mart_sales_vs_target[net_revenue] ),
    mart_sales_vs_target[is_latest] = TRUE (),
    mart_sales_vs_target[is_active_month] = TRUE (),
    mart_sales_vs_target[target_revenue] > 0
)
```
```dax
% Hoàn thành = DIVIDE ( [DT thuần có chỉ tiêu], [Chỉ tiêu hiện hành] )
```
```dax
Chỉ tiêu đầu năm (v1) =
CALCULATE (
    SUM ( mart_sales_vs_target[target_revenue] ),
    mart_sales_vs_target[plan_version] = "v1",
    mart_sales_vs_target[is_active_month] = TRUE (),
    mart_sales_vs_target[target_revenue] > 0
)
```
```dax
DT thuần so v1 =
CALCULATE (
    SUM ( mart_sales_vs_target[net_revenue] ),
    mart_sales_vs_target[plan_version] = "v1",
    mart_sales_vs_target[is_active_month] = TRUE (),
    mart_sales_vs_target[target_revenue] > 0
)
```
```dax
% Hoàn thành so v1 = DIVIDE ( [DT thuần so v1], [Chỉ tiêu đầu năm (v1)] )
```

Ba measure dưới không ghi tên phiên bản, nên khi có v3 thì ma trận tự thêm cột (BRD: không thiết kế cứng số phiên bản). `HASONEVALUE` để trống ô gộp nhiều phiên bản, tránh cộng doanh thu hai lần.

```dax
Chỉ tiêu theo phiên bản =
IF (
    HASONEVALUE ( mart_sales_vs_target[plan_version] ),
    CALCULATE (
        SUM ( mart_sales_vs_target[target_revenue] ),
        mart_sales_vs_target[is_active_month] = TRUE (),
        mart_sales_vs_target[target_revenue] > 0
    )
)
```
```dax
DT thuần theo phiên bản =
IF (
    HASONEVALUE ( mart_sales_vs_target[plan_version] ),
    CALCULATE (
        SUM ( mart_sales_vs_target[net_revenue] ),
        mart_sales_vs_target[is_active_month] = TRUE (),
        mart_sales_vs_target[target_revenue] > 0
    )
)
```
```dax
% HT theo phiên bản = DIVIDE ( [DT thuần theo phiên bản], [Chỉ tiêu theo phiên bản] )
```
```dax
Phiên bản áp dụng =
CALCULATE (
    CONCATENATEX ( VALUES ( mart_sales_vs_target[plan_version] ), mart_sales_vs_target[plan_version], ", " ),
    mart_sales_vs_target[is_latest] = TRUE (),
    mart_sales_vs_target[target_revenue] > 0
)
```

### Khách hàng và sản phẩm

```dax
Khách hàng mua =
CALCULATE ( DISTINCTCOUNT ( fact_sales[customer_id] ), fact_sales[is_delivered] = TRUE () )
```
```dax
Khách mới =
VAR NgayDau = MIN ( dim_date[full_date] )
VAR NgayCuoi = MAX ( dim_date[full_date] )
VAR KhachTrongKy =
    CALCULATETABLE ( VALUES ( fact_sales[customer_id] ), fact_sales[is_delivered] = TRUE () )
RETURN
    COUNTROWS (
        FILTER (
            KhachTrongKy,
            VAR NgayMuaDau =
                CALCULATE ( MIN ( fact_sales[order_date] ), ALL ( dim_date ), fact_sales[is_delivered] = TRUE () )
            RETURN NgayMuaDau >= NgayDau && NgayMuaDau <= NgayCuoi
        )
    )
```
```dax
Khách quay lại = [Khách hàng mua] - [Khách mới]
```
```dax
Khách churn =
VAR NgayThamChieu = MIN ( MAX ( dim_date[full_date] ), DATE ( 2024, 12, 31 ) )
RETURN
    COUNTROWS (
        FILTER (
            dim_customers,
            VAR NgayMuaCuoi =
                CALCULATE (
                    MAX ( fact_sales[order_date] ),
                    ALL ( dim_date ),
                    fact_sales[is_delivered] = TRUE (),
                    fact_sales[order_date] <= NgayThamChieu
                )
            RETURN
                dim_customers[status] = "Active"
                    && NOT ISBLANK ( NgayMuaCuoi )
                    && NgayThamChieu - NgayMuaCuoi > 90
        )
    )
```

Tham số Top N: Modeling, New parameter, Numeric range, tên `Top N`, từ 10 đến 20, bước 10, mặc định 10. Power BI tạo measure `Top N Value`.

```dax
Hạng khách hàng =
IF (
    NOT HASONEVALUE ( dim_customers[customer_id] ) || ISBLANK ( [Doanh thu] ),
    BLANK (),
    RANKX (
        ALLSELECTED ( dim_customers ),
        CALCULATE ( [Doanh thu], ALLSELECTED ( dim_employees ) )
    )
)
```
```dax
Trong Top N =
IF ( NOT ISBLANK ( [Hạng khách hàng] ) && [Hạng khách hàng] <= [Top N Value], 1, 0 )
```
```dax
SP không bán được =
COUNTROWS ( FILTER ( dim_products, COALESCE ( [Doanh thu], 0 ) = 0 ) )
```
```dax
Không bán được = IF ( COALESCE ( [Doanh thu], 0 ) = 0, 1, 0 )
```

### Nhân viên

```dax
DT 6 tháng đầu =
CALCULATE ( [Doanh thu], dim_date[year] = 2024, dim_date[month] <= 6 )
```
```dax
DT 6 tháng cuối =
CALCULATE ( [Doanh thu], dim_date[year] = 2024, dim_date[month] >= 7 )
```
```dax
% Tăng trưởng =
IF (
    [DT 6 tháng đầu] <= 0 || [DT 6 tháng cuối] <= 0,
    BLANK (),
    DIVIDE ( [DT 6 tháng cuối] - [DT 6 tháng đầu], [DT 6 tháng đầu] )
)
```
```dax
Xếp loại =
VAR TangTruong = [% Tăng trưởng]
RETURN
    SWITCH (
        TRUE (),
        ISBLANK ( TangTruong ), BLANK (),
        TangTruong >= 0.1, "Tăng trưởng tốt",
        TangTruong <= -0.1, "Sa sút",
        "Ổn định"
    )
```
```dax
NV tăng trưởng tốt =
COUNTROWS ( FILTER ( VALUES ( dim_employees[employee_id] ), [Xếp loại] = "Tăng trưởng tốt" ) )
```
```dax
NV ổn định =
COUNTROWS ( FILTER ( VALUES ( dim_employees[employee_id] ), [Xếp loại] = "Ổn định" ) )
```
```dax
NV sa sút =
COUNTROWS ( FILTER ( VALUES ( dim_employees[employee_id] ), [Xếp loại] = "Sa sút" ) )
```

### Nhà phân phối

```dax
Tổng đơn NPP = SUM ( mart_distributor_performance[total_orders] )
```
```dax
Giá trị đặt NPP = SUM ( mart_distributor_performance[total_order_value] )
```
```dax
Fill Rate =
DIVIDE (
    SUM ( mart_distributor_performance[qty_delivered_ontime] ),
    SUM ( mart_distributor_performance[qty_ordered] )
)
```
```dax
NPP hoạt động =
CALCULATE (
    DISTINCTCOUNT ( mart_distributor_performance[distributor_id] ),
    mart_distributor_performance[total_orders] > 0
)
```
```dax
NPP cảnh báo 30 ngày =
CALCULATE (
    DISTINCTCOUNT ( mart_distributor_performance[distributor_id] ),
    mart_distributor_performance[is_inactive_alert] = TRUE ()
)
```
```dax
Tỷ trọng kênh =
DIVIDE ( [Giá trị đặt NPP], CALCULATE ( [Giá trị đặt NPP], ALLSELECTED ( dim_distributors[channel] ) ) )
```
```dax
GT đặt 6 tháng đầu =
CALCULATE ( [Giá trị đặt NPP], dim_date[year] = 2024, dim_date[month] <= 6 )
```
```dax
GT đặt 6 tháng cuối =
CALCULATE ( [Giá trị đặt NPP], dim_date[year] = 2024, dim_date[month] >= 7 )
```
```dax
% Tăng trưởng NPP =
IF (
    [GT đặt 6 tháng đầu] <= 0 || [GT đặt 6 tháng cuối] <= 0,
    BLANK (),
    DIVIDE ( [GT đặt 6 tháng cuối] - [GT đặt 6 tháng đầu], [GT đặt 6 tháng đầu] )
)
```
```dax
Xếp loại NPP =
VAR TangTruong = [% Tăng trưởng NPP]
RETURN
    SWITCH (
        TRUE (),
        ISBLANK ( TangTruong ), BLANK (),
        TangTruong >= 0.1, "Tăng trưởng",
        TangTruong <= -0.1, "Giảm sút",
        "Ổn định"
    )
```
```dax
NPP giảm sút =
COUNTROWS ( FILTER ( VALUES ( dim_distributors[distributor_id] ), [Xếp loại NPP] = "Giảm sút" ) )
```
```dax
Ngày đặt gần nhất = MAX ( mart_distributor_performance[last_order_date] )
```
```dax
Số ngày không đặt = MAX ( mart_distributor_performance[days_since_last_order] )
```
```dax
Lý do cảnh báo =
IF (
    [NPP cảnh báo 30 ngày] > 0,
    IF ( ISBLANK ( [Ngày đặt gần nhất] ), "Chưa đặt đơn nào trong năm", "Quá 30 ngày không đặt" )
)
```
```dax
GT đặt lũy kế năm = TOTALYTD ( [Giá trị đặt NPP], dim_date[full_date] )
```
```dax
GT đặt tháng trước =
CALCULATE ( [Giá trị đặt NPP], DATEADD ( dim_date[full_date], -1, MONTH ) )
```
```dax
% so tháng trước =
IF (
    [GT đặt tháng trước] <= 0,
    BLANK (),
    DIVIDE ( [Giá trị đặt NPP] - [GT đặt tháng trước], [GT đặt tháng trước] )
)
```

Nếu `DATEADD` trả về trống dù bảng ngày đã đánh dấu, có thể thay `GT đặt tháng trước` bằng bản không dùng hàm thời gian (chỉ đúng khi dữ liệu nằm trong một năm):

```dax
GT đặt tháng trước =
VAR ThangTruoc = MAX ( dim_date[month] ) - 1
RETURN
    IF (
        ThangTruoc >= 1,
        CALCULATE (
            [Giá trị đặt NPP],
            REMOVEFILTERS ( dim_date ),
            dim_date[year] = 2024,
            dim_date[month] = ThangTruoc
        )
    )
```

## Thiết lập visual cần chú ý

| Trang | Visual | Thiết lập |
|---|---|---|
| Tổng quan | Bảng nhân viên | Tô nền cột % hoàn thành: ≥ 1 xanh, < 1 đỏ |
| Chỉ tiêu | Ma trận tháng × phiên bản | Tắt Column subtotals |
| Chỉ tiêu | Slicer phiên bản | Bộ lọc visual `plan_version` is not blank (6 dòng hàng trả tháng 7 của người đã nghỉ không có phiên bản). Không tick cứng v1, v2. Edit interactions: chỉ tác động lên ma trận nhân viên × tháng |
| Chỉ tiêu | Bảng lịch sử phiên bản | Cột ngày dùng Earliest hoặc Latest, không dùng Date Hierarchy |
| Khách hàng & SP | Top 10 / Bottom 10 sản phẩm | Bộ lọc Top N theo `Doanh thu`. Bottom 10 thêm `Doanh thu` > 0 |
| Khách hàng & SP | Top khách hàng | Bộ lọc visual `Trong Top N` is 1 |
| Khách hàng & SP | Sản phẩm không bán được | Bộ lọc visual `Không bán được` is 1 |
| Nhân viên | Slicer nhân viên | Hai cấp `full_name` rồi `employee_id` (có 2 cặp trùng tên). Edit interactions: không tác động lên bảng xếp loại và thẻ số |
| Nhân viên | Bảng xếp loại | Không đặt cột `region` (người chuyển vùng bị tách 2 dòng). Sparkline `Doanh thu` theo `dim_date[month]` |
| Kênh phân phối | Slicer vùng, kênh, cấp | Lấy từ `dim_distributors`, không dùng slicer vùng của nhân viên |
| Kênh phân phối | Bảng xu hướng NPP, thẻ NPP giảm sút | Slicer Quý, Tháng không tác động (Edit interactions) |
| Kênh phân phối | Danh sách cảnh báo | Bộ lọc visual `is_inactive_alert` = True, thêm cột `Lý do cảnh báo` |
| Hiệu suất NPP | Giá trị đặt và lũy kế | Đường lũy kế đặt trên trục phụ |

## Lỗi đã gặp

| Hiện tượng | Nguyên nhân | Cách sửa |
|---|---|---|
| Card lũy kế năm trống | Card không lọc ngày nên `TOTALYTD` tính cho năm 2026 | Lọc `dim_date[year] = 2024` cho mọi trang |
| Lũy kế bằng giá trị tháng, `% so tháng trước` trống | `dim_date` chưa được đánh dấu là bảng ngày | Mark as date table với `full_date` |
| Top khách hàng: ai cũng hạng 1, tổng bằng cả công ty | `RANKX` chỉ đổi `customer_id`, còn `customer_name` của dòng hiện tại vẫn lọc | Duyệt `ALLSELECTED ( dim_customers )` (cả bảng) |
| Top khách hàng có nhiều ô doanh thu trống | Bảng ghép mọi khách với mọi nhân viên, measure hạng luôn có giá trị | Trả về trống khi `Doanh thu` trống |
| `Trong Top N` giữ cả dòng không có hạng | DAX coi ô trống như 0, nên trống <= 10 là TRUE | Kiểm tra `NOT ISBLANK` trước khi so sánh |
| Danh sách cảnh báo chỉ có 1 dòng thay vì 14 | Power BI ẩn dòng khi mọi measure trên dòng đều trống (13 nhà phân phối chưa đặt đơn nào) | Thêm measure `Lý do cảnh báo` luôn có chữ khi bị cảnh báo |
| Slicer phiên bản có (Blank) | 6 dòng mart không có phiên bản | Bộ lọc visual is not blank |
| Số ngày không đặt bị nhân 12 | Cột lặp lại ở mọi tháng của một nhà phân phối | Dùng MAX, không dùng SUM |

## Số kiểm tra

Khi không chọn bộ lọc nào (đã lọc năm 2024). Mọi số tính lại được bằng SQL trên `dwh`.

**Tổng quan**

| Chỉ số | Giá trị |
|---|---|
| Doanh thu | 139.793.210.000 |
| Hàng trả bị trừ | 1.077.285.000 |
| Doanh thu thuần | 138.715.925.000 |
| DT thuần có chỉ tiêu | 138.594.961.100 |
| Chỉ tiêu hiện hành | 279.392.800.000 |
| % Hoàn thành | 49,61% |
| % Hoàn thành so v1 | 51,59% |
| SL hàng trả | 47.679 |
| Khách hàng mua | 1.802 |
| Nhân viên đạt từ 100% cả năm | 7 trên 111 |

**Chỉ tiêu**

| Phiên bản | Chỉ tiêu | DT thuần | % HT |
|---|---|---|---|
| v1 | 268.650.600.000 | 138.594.961.100 | 51,59% |
| v2 | 139.998.000.000 | 68.994.752.100 | 49,28% |

Tháng 1 đến 6 áp dụng v1, tháng 7 đến 12 áp dụng v2. Lịch sử: v1 ban hành 05/01/2024, 111 nhân viên, tổng 279.998.400.000. v2 ban hành 03/07/2024, 103 nhân viên, tổng 139.998.000.000.

**Khách hàng & SP**

| Chỉ số | Giá trị |
|---|---|
| Khách churn (đến 31/12/2024) | 311 |
| Sản phẩm không bán được | 8, đều `Discontinued` |
| Sản phẩm bán chạy nhất | Nước rửa chén Premium, 3.466.542.000 |
| Tổng Top 10 khách | 27.640.964.000 |
| Tổng Top 20 khách | 36.519.179.900 |
| Khách hạng 1 | Siêu thị Hồ Minh Lan, nhân viên Ngô Minh An, 8.615.030.600 |

**Nhân viên**

| Chỉ số | Giá trị |
|---|---|
| Tăng trưởng tốt, ổn định, sa sút | 36, 35, 23 |
| Đỗ Minh An (EMP1004) | Miền Bắc 538.183.300 đến 30/06, Miền Trung 724.968.300 từ 01/07, +34,7% |

**Kênh phân phối**

| Chỉ số | Giá trị |
|---|---|
| Tổng đơn NPP | 7.952 |
| Giá trị đặt NPP | 167.455.562.390 |
| Fill Rate | 34,42% |
| NPP hoạt động | 125 trên 138 |
| NPP cảnh báo 30 ngày | 14 (13 chưa đặt đơn nào, DIST0112 quá 31 ngày) |
| NPP giảm sút | 42 |
| Tỷ trọng kênh | Traditional Trade 42,0%, E-commerce 31,2%, Modern Trade 26,8% |

**Hiệu suất NPP**

| Chỉ số | Giá trị |
|---|---|
| Lũy kế đến tháng 6 | 83.995.847.220 |
| % so tháng trước, tháng 2 và tháng 12 | −45,0% và +21,3% |
