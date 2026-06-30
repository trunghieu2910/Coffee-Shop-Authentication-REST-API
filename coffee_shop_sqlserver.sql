-- ============================================================
--  COFFEE SHOP DATABASE  (SQL Server / SSMS)
--  Generated from ERD (Draw.io)
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'coffee_shop')
BEGIN
    ALTER DATABASE coffee_shop SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE coffee_shop;
END
GO

CREATE DATABASE coffee_shop
    COLLATE Vietnamese_CI_AS;
GO

USE coffee_shop;
GO

-- ============================================================
-- 1. roles
-- ============================================================
CREATE TABLE roles (
    role_id   INT          NOT NULL IDENTITY(1,1),
    role_name NVARCHAR(50) NOT NULL,

    CONSTRAINT pk_roles      PRIMARY KEY (role_id),
    CONSTRAINT uq_roles_name UNIQUE      (role_name)
);
GO

-- ============================================================
-- 2. users
-- ============================================================
CREATE TABLE users (
    user_id       INT            NOT NULL IDENTITY(1,1),
    role_id       INT            NOT NULL,
    first_name    NVARCHAR(100)  NOT NULL,
    last_name     NVARCHAR(100)  NOT NULL,
	username	  NVARCHAR(50)   NOT NULL,
    email         NVARCHAR(150)  NOT NULL,
    phone         NVARCHAR(20)   NOT NULL,
    password_hash NVARCHAR(255)  NOT NULL,
    status        BIT			 NOT NULL DEFAULT 1,   -- 'ACTIVE' | 'LOCKED'
    avatar_url    NVARCHAR(255)  NULL,
    created_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_users				PRIMARY KEY (user_id),
	CONSTRAINT uq_users_username	UNIQUE      (username),
    CONSTRAINT uq_users_email		UNIQUE      (email),
	CONSTRAINT uq_users_phone		UNIQUE      (phone),
    CONSTRAINT fk_users_role		FOREIGN KEY  (role_id) REFERENCES roles (role_id)
);
GO

-- ============================================================
-- 3. categories
-- ============================================================
CREATE TABLE categories (
    category_id INT            NOT NULL IDENTITY(1,1),
    name        NVARCHAR(100)  NOT NULL,
    is_active   BIT            NOT NULL DEFAULT 1,
    created_at  DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_categories PRIMARY KEY (category_id)
);
GO

-- ============================================================
-- 4. products
-- ============================================================
CREATE TABLE products (
    product_id   INT            NOT NULL IDENTITY(1,1),
    category_id  INT            NOT NULL,
    name         NVARCHAR(150)  NOT NULL,
    description  NVARCHAR(MAX)  NULL,
    is_available BIT            NOT NULL DEFAULT 1,
    is_active    BIT            NOT NULL DEFAULT 1,
    created_at   DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_products     PRIMARY KEY (product_id),
    CONSTRAINT fk_products_cat FOREIGN KEY (category_id) REFERENCES categories (category_id)
);
GO

-- ============================================================
-- 5. product_variants
-- ============================================================
CREATE TABLE product_variants (
    variant_id   INT            NOT NULL IDENTITY(1,1),
    product_id   INT            NOT NULL,
    variant_name NVARCHAR(100)  NOT NULL,
    size         NVARCHAR(5)    NULL,          -- 'S' | 'M' | 'L' | 'XL'
    temperature  NVARCHAR(10)   NULL,          -- 'HOT' | 'COLD' | 'ROOM'
    price        DECIMAL(10,2)  NOT NULL DEFAULT 0,
    is_available BIT            NOT NULL DEFAULT 1,

    CONSTRAINT pk_product_variants  PRIMARY KEY (variant_id),
    CONSTRAINT ck_variant_size      CHECK (size        IN ('S','M','L','XL')),
    CONSTRAINT ck_variant_temp      CHECK (temperature IN ('HOT','COLD','ROOM')),
    CONSTRAINT fk_variants_product  FOREIGN KEY (product_id) REFERENCES products (product_id)
);
GO

-- ============================================================
-- 6. product_images
-- ============================================================
CREATE TABLE product_images (
    image_id   INT            NOT NULL IDENTITY(1,1),
    product_id INT            NOT NULL,
    variant_id INT            NOT NULL,
    image_url  NVARCHAR(255)  NOT NULL,
    is_primary BIT            NOT NULL DEFAULT 0,
    created_at DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_product_images PRIMARY KEY (image_id),
    CONSTRAINT fk_images_product FOREIGN KEY (product_id) REFERENCES products         (product_id),
    CONSTRAINT fk_images_variant FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id)
);
GO

-- ============================================================
-- 7. payment_methods
-- ============================================================
CREATE TABLE payment_methods (
    payment_method_id INT           NOT NULL IDENTITY(1,1),
    name              NVARCHAR(100) NOT NULL,

    CONSTRAINT pk_payment_methods     PRIMARY KEY (payment_method_id),
    CONSTRAINT uq_payment_method_name UNIQUE      (name)
);
GO

-- ============================================================
-- 8. tables  (bàn trong quán)
-- ============================================================
CREATE TABLE tables (
    table_id  INT           NOT NULL IDENTITY(1,1),
    capacity  INT           NOT NULL,
    status    NVARCHAR(15)  NOT NULL DEFAULT 'AVAILABLE',  -- 'AVAILABLE'|'OCCUPIED'|'RESERVED'|'MAINTENANCE'
    is_active BIT           NOT NULL DEFAULT 1,

    CONSTRAINT pk_tables    PRIMARY KEY (table_id),
    CONSTRAINT ck_tbl_status CHECK (status IN ('AVAILABLE','OCCUPIED','RESERVED','MAINTENANCE'))
);
GO

-- ============================================================
-- 20. customer_addresses  (địa chỉ giao hàng của Customer)
-- ============================================================
CREATE TABLE customer_addresses (
    address_id    INT            NOT NULL IDENTITY(1,1),
    customer_id   INT            NOT NULL,   -- FK → users (chỉ role Customer)
    label         NVARCHAR(50)   NULL,       -- 'Nhà', 'Cơ quan', v.v.
    full_address  NVARCHAR(500)  NOT NULL,
    recipient_name  NVARCHAR(150) NOT NULL,
    recipient_phone NVARCHAR(20)  NOT NULL,
    created_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
 
    CONSTRAINT pk_customer_addresses   PRIMARY KEY (address_id),
    CONSTRAINT fk_addr_customer        FOREIGN KEY (customer_id) REFERENCES users (user_id)
);
GO

-- ============================================================
-- 9. orders
-- ============================================================
CREATE TABLE orders (
    order_id			INT            NOT NULL IDENTITY(1,1),
    user_id				INT				   NOT NULL,        
    table_id			INT            NULL,        -- NULL nếu mang về / online
    order_type			NVARCHAR(10)   NOT NULL,    -- 'ONLINE' | 'COUNTER'
    order_status		NVARCHAR(15)   NOT NULL DEFAULT 'PENDING',
    subtotal			DECIMAL(10,2)  NOT NULL DEFAULT 0,
    discount_amount		DECIMAL(10,2)  NOT NULL DEFAULT 0,
    total_amount		DECIMAL(10,2)  NOT NULL DEFAULT 0,
    points_earned		INT            NOT NULL DEFAULT 0,
    note				NVARCHAR(MAX)  NULL,
	delivery_address_id INT			   NULL,   -- NULL nếu table_id NOT NULL
    shipping_fee        DECIMAL(10,2)  NOT NULL DEFAULT 0,
    created_at			DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at			DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_orders			PRIMARY KEY (order_id),
    CONSTRAINT ck_order_type		CHECK (order_type   IN ('ONLINE','COUNTER')),
    CONSTRAINT ck_order_status		CHECK (order_status IN ('PENDING','CONFIRMED','PREPARING','READY','COMPLETED','CANCELLED')),
    CONSTRAINT fk_orders_user		FOREIGN KEY (user_id) REFERENCES users  (user_id),
    CONSTRAINT fk_orders_table		FOREIGN KEY (table_id)    REFERENCES tables (table_id),
	CONSTRAINT fk_orders_address	FOREIGN KEY (delivery_address_id) REFERENCES customer_addresses (address_id)
);
GO

-- ============================================================
-- 10. order_details
-- ============================================================
CREATE TABLE order_details (
    item_id               INT            NOT NULL IDENTITY(1,1),
    order_id              INT            NOT NULL,
    product_id            INT            NOT NULL,
    variant_id            INT            NOT NULL,
    product_name_snapshot NVARCHAR(150)  NOT NULL,
    variant_name_snapshot NVARCHAR(100)  NULL,
    price_snapshot        DECIMAL(10,2)  NOT NULL,
    quantity              INT            NOT NULL,
    item_total            DECIMAL(10,2)  NOT NULL,
    special_note          NVARCHAR(MAX)  NULL,
    item_status           NVARCHAR(15)   NOT NULL DEFAULT 'PENDING',

    CONSTRAINT pk_order_details  PRIMARY KEY (item_id),
    CONSTRAINT ck_od_quantity    CHECK (quantity    > 0),
    CONSTRAINT ck_od_status      CHECK (item_status IN ('PENDING','PREPARING','COMPLETED','CANCELLED')),
    CONSTRAINT fk_od_order       FOREIGN KEY (order_id)   REFERENCES orders           (order_id),
    CONSTRAINT fk_od_product     FOREIGN KEY (product_id) REFERENCES products          (product_id),
    CONSTRAINT fk_od_variant     FOREIGN KEY (variant_id) REFERENCES product_variants  (variant_id)
);
GO

-- ============================================================
-- 11. payments
-- ============================================================
CREATE TABLE payments (
    payment_id        INT            NOT NULL IDENTITY(1,1),
    order_id          INT            NOT NULL,
    payment_method_id INT            NOT NULL,
    amount            DECIMAL(10,2)  NOT NULL,
    payment_status    NVARCHAR(10)   NOT NULL DEFAULT 'PENDING', -- 'PENDING'|'SUCCESS'|'FAILED'|'REFUNDED'
    transaction_ref   NVARCHAR(100)  NULL,
    gateway_response  NVARCHAR(MAX)  NULL,
    paid_at           DATETIME2      NULL,
    created_at        DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_payments				PRIMARY KEY (payment_id),
    CONSTRAINT ck_pay_status			CHECK (payment_status IN ('PENDING','SUCCESS','FAILED','REFUNDED')),
    CONSTRAINT fk_payments_order		FOREIGN KEY (order_id)          REFERENCES orders          (order_id),
    CONSTRAINT fk_payments_payments_method		FOREIGN KEY (payment_method_id) REFERENCES payment_methods (payment_method_id),
	CONSTRAINT uq_payments_order_id 				UNIQUE      (order_id)
);
GO

-- ============================================================
-- 12. reservations
-- ============================================================
CREATE TABLE reservations (
    reservation_id      INT            NOT NULL IDENTITY(1,1),
    customer_id         INT            NOT NULL,   
    cancelled_by        INT            NULL,   -- FK → users, ai hủy
    order_id            INT            NULL,   -- đơn hàng phát sinh từ reservation
    party_size          INT            NOT NULL,
    reservation_date    DATE           NOT NULL,
    reservation_time    TIME           NOT NULL,
    duration_minutes    INT            NOT NULL,
    status              NVARCHAR(15)   NOT NULL DEFAULT 'PENDING',
    cancellation_reason NVARCHAR(MAX)  NULL,
    cancelled_at        DATETIME2      NULL,
    note                NVARCHAR(MAX)  NULL,
    created_at          DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at          DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_reservations          PRIMARY KEY (reservation_id),
    CONSTRAINT ck_res_status            CHECK (status IN ('PENDING','CONFIRMED','ARRIVED','COMPLETED','CANCELLED','NO_SHOW')),
    CONSTRAINT fk_reservations_customer FOREIGN KEY (customer_id)  REFERENCES users  (user_id),
    CONSTRAINT fk_reservations_cancel   FOREIGN KEY (cancelled_by) REFERENCES users  (user_id),
    CONSTRAINT fk_reservations_order    FOREIGN KEY (order_id)     REFERENCES orders (order_id),
	CONSTRAINT uq_reservations_order_id 	UNIQUE      (order_id)
);
GO

-- ============================================================
-- 13. reservation_tables  (bảng trung gian: 1 reservation nhiều bàn)
-- ============================================================
CREATE TABLE reservation_tables (
    id             INT NOT NULL IDENTITY(1,1),
    reservation_id INT NOT NULL,
    table_id       INT NOT NULL,

    CONSTRAINT pk_reservation_tables PRIMARY KEY (id),
    CONSTRAINT uq_reservation_table  UNIQUE      (reservation_id, table_id),
    CONSTRAINT fk_rt_reservation     FOREIGN KEY (reservation_id) REFERENCES reservations (reservation_id),
    CONSTRAINT fk_rt_table           FOREIGN KEY (table_id)       REFERENCES tables        (table_id)
);
GO

-- ============================================================
-- 14. reservation_deposits
-- ============================================================
CREATE TABLE reservation_deposits (
    deposit_id      INT            NOT NULL IDENTITY(1,1),
    reservation_id  INT            NOT NULL,
    deposit_amount  DECIMAL(10,2)  NOT NULL,
    payment_method_id INT          NULL,
    payment_status  NVARCHAR(15)   NOT NULL DEFAULT 'PENDING',
    transaction_ref NVARCHAR(100)  NULL,
    refund_amount   DECIMAL(10,2)  NOT NULL DEFAULT 0,
    refund_status   NVARCHAR(10)   NOT NULL DEFAULT 'NONE',  -- 'NONE'|'PARTIAL'|'FULL'
    refund_note     NVARCHAR(MAX)  NULL,
    applied_to_order BIT           NOT NULL DEFAULT 0,
    created_at      DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_reservation_deposits PRIMARY KEY (deposit_id),
    CONSTRAINT uq_deposit_reservation  UNIQUE      (reservation_id),
    CONSTRAINT ck_deposit_pay_status   CHECK (payment_status IN ('PENDING','PAID','REFUNDED','CANCELLED','FORFEITED')),
    CONSTRAINT ck_deposit_refund_status CHECK (refund_status IN ('NONE','PARTIAL','FULL')),
    CONSTRAINT fk_deposit_reservation  FOREIGN KEY (reservation_id) REFERENCES reservations (reservation_id),
	CONSTRAINT fk_reservation_deposits_payments_method		FOREIGN KEY (payment_method_id) REFERENCES payment_methods (payment_method_id)
);
GO

-- ============================================================
-- 15. reviews
-- ============================================================
CREATE TABLE reviews (
    review_id     INT            NOT NULL IDENTITY(1,1),
    customer_id   INT            NOT NULL,
    order_id      INT            NOT NULL,
    product_id    INT            NOT NULL,   
    rating        TINYINT        NOT NULL,
    comment       NVARCHAR(MAX)  NULL,
    is_visible    BIT            NOT NULL DEFAULT 1,
    points_earned   INT          NOT NULL DEFAULT 0,
    created_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_reviews          PRIMARY KEY (review_id),
    CONSTRAINT ck_review_rating    CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT uq_review_per_item  UNIQUE      (customer_id, order_id, product_id),
    CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES users    (user_id),
    CONSTRAINT fk_reviews_order    FOREIGN KEY (order_id)    REFERENCES orders   (order_id),
    CONSTRAINT fk_reviews_product  FOREIGN KEY (product_id)  REFERENCES products (product_id)
);
GO

-- ============================================================
-- 16. loyalty_points
-- ============================================================
CREATE TABLE loyalty_points (
    point_id         INT            NOT NULL IDENTITY(1,1),
    customer_id      INT            NOT NULL,
    transaction_type NVARCHAR(10)   NOT NULL,   -- 'EARN'|'REDEEM'
    points           INT            NOT NULL,   -- dương = cộng, âm = trừ
    balance_after    INT            NOT NULL,
    reference_type   NVARCHAR(10)   NULL,       -- 'ORDER'|'REVIEW'
    reference_id     INT            NULL,       -- order_id hoặc review_id
    note             NVARCHAR(255)  NULL,
    created_at       DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_loyalty_points    PRIMARY KEY (point_id),
    CONSTRAINT ck_lp_trans_type     CHECK (transaction_type IN ('EARN','REDEEM','ADJUST')),
    CONSTRAINT ck_lp_ref_type       CHECK (reference_type   IN ('ORDER','REVIEW')),
    CONSTRAINT fk_lp_customer       FOREIGN KEY (customer_id) REFERENCES users (user_id)
);
GO

-- ============================================================
-- 17. policies  (chính sách tích điểm / giảm giá)
-- ============================================================
CREATE TABLE policies (
    policy_id      INT            NOT NULL IDENTITY(1,1),
    comment        NVARCHAR(MAX)  NULL,
    currency_value DECIMAL(10,2)  NOT NULL DEFAULT 0,
    unit           NVARCHAR(50)   NULL,
    status         BIT				NOT NULL DEFAULT 1,  -- 'ACTIVE'|'INACTIVE'

	action_type	   NVARCHAR(15)   NOT NULL,		-- 'DISCOUNT'|'ORDER'|'REVIEW'
	policy_type    NVARCHAR(15)   NOT NULL,		-- 'EARN'|'REDEEM'
	policy_name    NVARCHAR(150)   NOT NULL,
	created_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_policies   PRIMARY KEY (policy_id),
    CONSTRAINT ck_pol_action_type CHECK (action_type IN ('DISCOUNT','ORDER','REVIEW')),
	CONSTRAINT ck_pol_policy_type CHECK (policy_type IN ('EARN','REDEEM'))
);
GO

-- ============================================================
-- 18. map  (sơ đồ mặt bằng quán)
-- ============================================================
CREATE TABLE map (
    map_id   INT            NOT NULL IDENTITY(1,1),
    map_name NVARCHAR(100)  NOT NULL,
    url_map  NVARCHAR(255)  NOT NULL,

    CONSTRAINT pk_map PRIMARY KEY (map_id)
);
GO

-- ============================================================
-- 19. system_logs
-- ============================================================
CREATE TABLE system_logs (
    log_id      INT            NOT NULL IDENTITY(1,1),
    user_id     INT            NULL,           -- NULL nếu hành động hệ thống
    action      NVARCHAR(100)  NOT NULL,
    target_type NVARCHAR(50)   NULL,           -- tên bảng bị tác động
    target_id   INT            NULL,           -- id bản ghi bị tác động
    description NVARCHAR(MAX)  NULL,
    ip_address  NVARCHAR(45)   NULL,
    created_at  DATETIME2      NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_system_logs PRIMARY KEY (log_id),
    CONSTRAINT fk_logs_user   FOREIGN KEY (user_id) REFERENCES users (user_id)
);
GO

-- ============================================================
-- 21. carts  (giỏ hàng — 1 customer 1 giỏ active)
-- ============================================================
CREATE TABLE carts (
    cart_id     INT       NOT NULL IDENTITY(1,1),
    customer_id INT       NOT NULL,
    created_at  DATETIME2 NOT NULL DEFAULT SYSDATETIME()
 
    CONSTRAINT pk_carts         PRIMARY KEY (cart_id),
    CONSTRAINT uq_carts_user    UNIQUE      (customer_id),   -- 1 user 1 giỏ
    CONSTRAINT fk_carts_user    FOREIGN KEY (customer_id) REFERENCES users (user_id)
);
GO

-- ============================================================
-- 22. cart_items  (các món trong giỏ hàng)
-- ============================================================
CREATE TABLE cart_items (
    cart_item_id INT            NOT NULL IDENTITY(1,1),
    cart_id      INT            NOT NULL,
    product_id   INT            NOT NULL,
    variant_id   INT            NOT NULL,
    quantity     INT            NOT NULL DEFAULT 1,
    special_note NVARCHAR(MAX)  NULL,       -- ít đường, không đá, v.v.
    added_at     DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
 
    CONSTRAINT pk_cart_items         PRIMARY KEY (cart_item_id),
    CONSTRAINT uq_cart_variant       UNIQUE      (cart_id, variant_id),  -- 1 variant 1 dòng, tăng qty thay vì thêm dòng mới
    CONSTRAINT ck_cart_item_qty      CHECK       (quantity > 0),
    CONSTRAINT fk_cart_items_cart    FOREIGN KEY (cart_id)    REFERENCES carts            (cart_id),
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES products         (product_id),
    CONSTRAINT fk_cart_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id)
);
GO

-- ============================================================
-- TRIGGERS: tự động cập nhật updated_at
-- ============================================================
CREATE TRIGGER trg_users_updated_at
ON users AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE users SET updated_at = SYSDATETIME()
    WHERE user_id IN (SELECT user_id FROM inserted);
END;
GO

CREATE TRIGGER trg_products_updated_at
ON products AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE products SET updated_at = SYSDATETIME()
    WHERE product_id IN (SELECT product_id FROM inserted);
END;
GO

CREATE TRIGGER trg_orders_updated_at
ON orders AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE orders SET updated_at = SYSDATETIME()
    WHERE order_id IN (SELECT order_id FROM inserted);
END;
GO

CREATE TRIGGER trg_reservations_updated_at
ON reservations AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE reservations SET updated_at = SYSDATETIME()
    WHERE reservation_id IN (SELECT reservation_id FROM inserted);
END;
GO

CREATE TRIGGER trg_reservation_deposits_updated_at
ON reservation_deposits AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE reservation_deposits SET updated_at = SYSDATETIME()
    WHERE deposit_id IN (SELECT deposit_id FROM inserted);
END;
GO

CREATE TRIGGER trg_policies_updated_at
ON policies AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE policies SET updated_at = SYSDATETIME()
    WHERE policy_id IN (SELECT policy_id FROM inserted);
END;
GO

CREATE TRIGGER trg_customer_addresses_updated_at
ON customer_addresses AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE customer_addresses
    SET    updated_at = SYSDATETIME()
    WHERE  address_id IN (SELECT address_id FROM inserted);
END;
GO
 
CREATE TRIGGER trg_cart_items_updated_at
ON cart_items AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE cart_items
    SET    updated_at = SYSDATETIME()
    WHERE  cart_item_id IN (SELECT cart_item_id FROM inserted);
END;
GO

-- ============================================================
-- SEED DATA: roles & payment_methods
-- ============================================================
-- 1. Bảng ROLES (Phân quyền)
INSERT INTO roles (role_name) VALUES
(N'Admin'), (N'Manager'), (N'Cashier'), (N'Barista'), (N'Customer');
GO

-- 2. Bảng USERS (Người dùng - Giả định status 1 là Active)
INSERT INTO users (first_name, last_name, username, email, phone, password_hash, status, avatar_url, role_id) VALUES
(N'Nguyễn', N'Văn A', 'User1', 'nguyenvana@gmail.com', '0901234561', 'hashed_pw_1', 1, 'avatar1.png', 1),
(N'Trần', N'Thị B', 'User2', 'tranthib@gmail.com', '0901234562', 'hashed_pw_2', 1, 'avatar2.png', 2),
(N'Lê', N'Văn C', 'User3', 'levanc@gmail.com', '0901234563', 'hashed_pw_3', 1, 'avatar3.png',3 ),
(N'Phạm', N'Thị D', 'User4', 'phamthid@gmail.com', '0901234564', 'hashed_pw_4', 1, 'avatar4.png', 4),
(N'Hoàng', N'Văn E', 'User5', 'hoangvane@gmail.com', '0901234565', 'hashed_pw_5', 1, 'avatar5.png', 5),
(N'Đỗ', N'Thị F', 'User6', 'dothif@gmail.com', '0901234566', 'hashed_pw_6', 1, 'avatar6.png', 1),
(N'Vũ', N'Văn G', 'User7', 'vuvang@gmail.com', '0901234567', 'hashed_pw_7', 1, 'avatar7.png', 2),
(N'Ngô', N'Thị H', 'User8', 'ngothih@gmail.com', '0901234568', 'hashed_pw_8', 1, 'avatar8.png', 3),
(N'Bùi', N'Văn I', 'User9', 'buivani@gmail.com', '0901234569', 'hashed_pw_9', 1, 'avatar9.png', 4),
(N'Đặng', N'Thị K', 'User10', 'dangthik@gmail.com', '0901234570', 'hashed_pw_10', 1, 'avatar10.png', 5);
GO

-- 3. Bảng CATEGORIES (Danh mục sản phẩm)
INSERT INTO categories (name, is_active) VALUES
(N'Cà phê pha máy', 1), (N'Cà phê truyền thống', 1), (N'Trà trái cây', 1), 
(N'Trà sữa', 1), (N'Đá xay (Frappuccino)', 1), (N'Bánh ngọt', 1), 
(N'Bánh mặn', 1), (N'Nước ép tươi', 1), (N'Sữa chua', 1), (N'Hạt cà phê / Merchandise', 1);
GO

-- 4. Bảng PRODUCTS (Sản phẩm)
INSERT INTO products (category_id, name, description, is_active) VALUES
(1, N'Espresso', N'Cà phê nguyên bản đậm đà', 1),
(1, N'Latte', N'Espresso kết hợp sữa tươi đánh béo', 1),
(2, N'Cà phê Đen Đá', N'Cà phê phin Việt Nam', 1),
(2, N'Bạc Xỉu', N'Sữa đặc, sữa tươi và chút cà phê', 1),
(3, N'Trà Đào Cam Sả', N'Trà thanh mát giải nhiệt', 1),
(4, N'Trà Sữa Trân Châu', N'Trà sữa truyền thống', 1),
(5, N'Matcha Đá Xay', N'Bột trà xanh Nhật Bản đá xay', 1),
(6, N'Tiramisu', N'Bánh ngọt phô mai nước Ý', 1),
(7, N'Bánh Mì Pate', N'Bánh mì giòn rụm', 1),
(8, N'Nước Ép Cam', N'Cam vắt tươi 100%', 1);
GO

-- 5. Bảng PRODUCT_VARIANTS (Biến thể sản phẩm)
INSERT INTO product_variants (product_id, variant_name, size, price, temperature, is_available) VALUES
(1, N'Espresso Single', 'S', 35000, 'HOT', 1),
(1, N'Espresso Double', 'S', 45000, 'HOT', 1),
(2, N'Latte Nóng Lớn', 'L', 55000, 'HOT', 1),
(2, N'Latte Đá Vừa', 'M', 45000, 'COLD', 1),
(2, N'Latte Đá Lớn', 'L', 55000, 'COLD', 1),
(2, N'Latte Nóng Vừa', 'M', 45000, 'HOT', 1),
(3, N'Đen Đá Lớn', 'L', 35000, 'COLD', 1),
(3, N'Đen Đá Vừa', 'M', 29000, 'COLD', 1),
(3, N'Đen Nóng', 'S', 29000, 'HOT', 1),
(4, N'Bạc Xỉu Lớn', 'L', 49000, 'COLD', 1),
(4, N'Bạc Xỉu Nóng', 'M', 39000, 'HOT', 1),
(4, N'Bạc Xỉu Vừa', 'M', 39000, 'COLD', 1),
(5, N'Trà Đào Cam Sả Lớn', 'L', 55000, 'COLD', 1),
(5, N'Trà Đào Cam Sả Vừa', 'M', 45000, 'COLD', 1),
(5, N'Trà Đào Nóng', 'M', 45000, 'HOT', 1),
(6, N'Trà Sữa Size L', 'L', 50000, 'COLD', 1),
(6, N'Trà Sữa Nóng Size M', 'M', 40000, 'HOT', 1),
(6, N'Trà Sữa Size M', 'M', 40000, 'COLD', 1),
(7, N'Matcha Đá Xay Lớn', 'L', 65000, 'COLD', 1),
(7, N'Matcha Đá Xay Vừa', 'M', 55000, 'COLD', 1),
(7, N'Matcha Không Kem Chesse', 'L', 60000, 'COLD', 1),
(8, N'Tiramisu Cắt Lát', 'M', 45000, 'COLD', 1),
(8, N'Tiramisu Nguyên Ổ Nhỏ', 'L', 250000, 'COLD', 1),
(9, N'Bánh Mì Thêm Pate', 'M', 35000, 'HOT', 1),
(9, N'Bánh Mì Xúc Xích', 'M', 35000, 'HOT', 1),
(9, N'Bánh Mì Thập Cẩm', 'M', 30000, 'HOT', 1),
(10, N'Ép Cam Ít Đường', 'M', 50000, 'COLD', 1),
(10, N'Ép Cam Lớn', 'L', 65000, 'COLD', 1),
(10, N'Ép Cam Cà Rốt', 'M', 55000, 'COLD', 1),
(10, N'Ép Cam Không Đường', 'M', 50000, 'COLD', 1);
GO

-- 6. Bảng PRODUCT_IMAGES (Hình ảnh sản phẩm)
INSERT INTO product_images (product_id, image_url, is_primary, variant_id) VALUES
(1, 'img/products/espresso.jpg', 1, 1), (2, 'img/products/latte.jpg', 1, 3),
(3, 'img/products/denda.jpg', 1, 7), (4, 'img/products/bacxiu.jpg', 1, 10),
(5, 'img/products/tradao.jpg', 1, 13), (6, 'img/products/trasua.jpg', 1, 16),
(7, 'img/products/matcha.jpg', 1, 19), (8, 'img/products/tiramisu.jpg', 1, 22),
(9, 'img/products/banhmi.jpg', 1, 24), (10, 'img/products/epcam.jpg', 1, 28);
GO

-- 7. Bảng PAYMENT_METHODS (Phương thức thanh toán)
INSERT INTO payment_methods (name) VALUES
(N'Tiền mặt'), (N'VNPay'), (N'Momo'), (N'ZaloPay'), (N'Thẻ Visa/Mastercard'),
(N'ShopeePay'), (N'Apple Pay'), (N'Chuyển khoản NH'), (N'Điểm tích lũy'), (N'Thẻ thành viên');
GO

-- 8. Bảng TABLES (Danh sách bàn)
INSERT INTO tables (capacity, status, is_active) VALUES
(2, 'AVAILABLE', 1), (2, 'AVAILABLE', 1), (4, 'OCCUPIED', 1),
(4, 'AVAILABLE', 1), (4, 'RESERVED', 1), (6, 'AVAILABLE', 1),
(6, 'AVAILABLE', 1), (8, 'AVAILABLE', 1), (2, 'MAINTENANCE', 0), (10, 'AVAILABLE', 1);
GO

-- 9. Bảng ORDERS (Đơn hàng)
INSERT INTO orders (user_id, table_id, order_type, order_status, subtotal, discount_amount, total_amount, points_earned, note) VALUES
(5, NULL, 'ONLINE', 'COMPLETED', 70000, 0, 70000, 7, NULL),
(6, NULL, 'ONLINE', 'COMPLETED', 45000, 5000, 40000, 4, N'Ít đá'),
(7, NULL, 'ONLINE', 'PREPARING', 150000, 15000, 135000, 0, N'Giao giờ hành chính'), 
(8, NULL, 'ONLINE', 'COMPLETED', 110000, 0, 110000, 11, NULL),
(9, NULL, 'ONLINE', 'CANCELLED', 55000, 0, 55000, 0, NULL), 
(10, NULL, 'ONLINE', 'COMPLETED', 210000, 20000, 190000, 19, N'Khách VIP'),
(5, NULL, 'ONLINE', 'COMPLETED', 90000, 0, 90000, 9, NULL),
(6, NULL, 'ONLINE', 'PENDING', 35000, 0, 35000, 0, NULL),
(7, NULL, 'ONLINE', 'COMPLETED', 130000, 0, 130000, 13, NULL),
(8, NULL, 'ONLINE', 'COMPLETED', 65000, 5000, 60000, 6, NULL),
(5, NULL, 'ONLINE', 'COMPLETED', 100000, 0, 100000, 10, N'Khách gọi thêm'),
(6, NULL, 'ONLINE', 'COMPLETED', 135000, 15000, 120000, 12, NULL),
(7, NULL, 'ONLINE', 'PREPARING', 250000, 0, 250000, 0, N'Giao cẩn thận kẻo hỏng bánh'),
(8, 1, 'COUNTER', 'COMPLETED', 105000, 0, 105000, 10, N'Làm nóng bánh'),
(9, 4, 'COUNTER', 'COMPLETED', 147000, 0, 147000, 14, NULL),
(10, 6, 'COUNTER', 'PENDING', 87000, 0, 87000, 0, N'Đang chờ bạn khách đến'), 
(5, NULL, 'ONLINE', 'COMPLETED', 155000, 0, 155000, 15, N'Giao kèm nhiều ống hút');
GO

-- 10. Bảng ORDER_DETAILS (Chi tiết đơn hàng)
INSERT INTO order_details (order_id, product_id, variant_id, product_name_snapshot, variant_name_snapshot, price_snapshot, quantity, item_total, special_note, item_status) VALUES
(1, 1, 1, N'Espresso', N'Espresso Single', 35000, 2, 70000, NULL, 'COMPLETED'),
(2, 2, 2, N'Latte', N'Latte Nóng Vừa', 45000, 1, 45000, N'Pha bằng sữa hạt macca', 'COMPLETED'), 
(3, 5, 5, N'Trà Đào Cam Sả', N'Trà Đào Cam Sả Lớn', 55000, 1, 55000, N'Ít đá, nhiều đào', 'PREPARING'),
(3, 8, 8, N'Tiramisu', N'Tiramisu Cắt Lát', 45000, 2, 90000, NULL, 'PREPARING'),
(4, 7, 7, N'Matcha Đá Xay', N'Matcha Đá Xay Lớn', 65000, 1, 65000, NULL, 'COMPLETED'),
(4, 8, 8, N'Tiramisu', N'Tiramisu Cắt Lát', 45000, 1, 45000, NULL, 'COMPLETED'),
(5, 5, 5, N'Trà Đào Cam Sả', N'Trà Đào Cam Sả Lớn', 55000, 1, 55000, NULL, 'CANCELLED'),
(7, 6, 6, N'Trà Sữa Trân Châu', N'Trà Sữa Size M', 40000, 1, 40000, N'Không lấy trân châu', 'COMPLETED'),
(8, 3, 3, N'Cà phê Đen Đá', N'Đen Đá Lớn', 35000, 1, 35000, NULL, 'PREPARING'),
(9, 7, 7, N'Matcha Đá Xay', N'Matcha Đá Xay Lớn', 65000, 2, 130000, NULL, 'COMPLETED'),
(6, 6, 6, N'Trà Sữa Trân Châu', N'Trà Sữa Size M', 40000, 3, 120000, NULL, 'COMPLETED'),
(6, 9, 9, N'Bánh Mì Pate', N'Bánh Mì Thập Cẩm', 30000, 3, 90000, N'Cắt làm đôi giúp', 'COMPLETED'),
(7, 10, 10, N'Nước Ép Cam', N'Ép Cam Không Đường', 50000, 1, 50000, NULL, 'COMPLETED'),
(10, 7, 7, N'Matcha Đá Xay', N'Matcha Đá Xay Lớn', 65000, 1, 65000, NULL, 'COMPLETED'),
(11, 6, 21, N'Trà Sữa Trân Châu', N'Trà Sữa Size L', 50000, 2, 100000, N'50% đá, 30% đường', 'COMPLETED'),
(12, 2, 13, N'Latte', N'Latte Đá Vừa', 45000, 3, 135000, NULL, 'COMPLETED'),
(13, 8, 25, N'Tiramisu', N'Tiramisu Nguyên Ổ Nhỏ', 250000, 1, 250000, N'Viết chữ "Happy Birthday Nam" + 1 nến', 'PREPARING'),
(14, 9, 26, N'Bánh Mì Pate', N'Bánh Mì Thêm Pate', 35000, 3, 105000, NULL, 'COMPLETED'),
(15, 4, 17, N'Bạc Xỉu', N'Bạc Xỉu Lớn', 49000, 3, 147000, NULL, 'COMPLETED'),
(16, 3, 15, N'Cà phê Đen Đá', N'Đen Đá Vừa', 29000, 3, 87000, NULL, 'PENDING'),
(17, 10, 30, N'Nước Ép Cam', N'Ép Cam Cà Rốt', 55000, 1, 55000, NULL, 'COMPLETED'),
(17, 10, 28, N'Nước Ép Cam', N'Ép Cam Ít Đường', 50000, 1, 50000, NULL, 'COMPLETED'),
(17, 10, 10, N'Nước Ép Cam', N'Ép Cam Không Đường', 50000, 1, 50000, NULL, 'COMPLETED');
GO

-- 11. Bảng PAYMENTS (Thanh toán đơn hàng)
INSERT INTO payments (order_id, payment_method_id, amount, payment_status, transaction_ref) VALUES
(1, 1, 70000, 'SUCCESS', 'PAY001'),
(2, 3, 40000, 'SUCCESS', 'PAY002'),
(3, 2, 135000, 'PENDING', 'PAY003'),
(4, 1, 110000, 'SUCCESS', 'PAY004'),
(6, 5, 190000, 'SUCCESS', 'PAY005'),
(7, 4, 90000, 'SUCCESS', 'PAY006'),
(9, 1, 130000, 'SUCCESS', 'PAY007'),
(10, 3, 60000, 'SUCCESS', 'PAY008');
GO

-- 12. Bảng RESERVATIONS (Đặt bàn)
INSERT INTO reservations (customer_id, order_id, party_size, reservation_date, reservation_time, duration_minutes, status, cancellation_reason, note) VALUES
(5, 1, 2, '2026-06-14', '18:00:00', 120, 'COMPLETED', NULL, N'Bàn góc yên tĩnh'),
(6, 2, 4, '2026-06-15', '19:00:00', 120, 'CONFIRMED', NULL, N'Tiệc sinh nhật'),
(7, 3, 2, '2026-06-15', '09:00:00', 60, 'PENDING', NULL, NULL),
(8, 4, 6, '2026-06-16', '20:00:00', 180, 'CANCELLED', N'Khách đổi lịch', NULL),
(9, 5, 2, '2026-06-16', '14:00:00', 90, 'CONFIRMED', NULL, N'Gần cửa sổ'),
(10, 6, 8, '2026-06-17', '18:30:00', 150, 'PENDING', NULL, N'Họp nhóm'),
(5, 7, 4, '2026-06-18', '10:00:00', 120, 'CONFIRMED', NULL, NULL),
(6, 8, 2, '2026-06-18', '20:00:00', 60, 'CANCELLED', N'Khách báo bận', NULL),
(7, 9, 6, '2026-06-19', '19:00:00', 120, 'PENDING', NULL, N'Cần ghế em bé'),
(8, NULL, 2, '2026-06-20', '08:00:00', 60, 'CONFIRMED', NULL, NULL);
GO
-- 13. Bảng RESERVATION_TABLES (Bàn được xếp cho đặt bàn)
INSERT INTO reservation_tables (reservation_id, table_id) VALUES
(1, 1), (2, 4), (4, 6), (5, 2), (7, 5), (8, 2), (10, 1);
GO

-- 14. Bảng RESERVATION_DEPOSITS (Tiền cọc đặt bàn)
INSERT INTO reservation_deposits (reservation_id, deposit_amount, payment_status, transaction_ref, refund_amount, refund_status) VALUES
(2, 100000, 'PAID', 'DEP001', 0, 'NONE'),
(4, 200000, 'REFUNDED', 'DEP002', 200000, 'FULL'),
(5, 50000, 'PAID', 'DEP003', 0, 'NONE'),
(7, 100000, 'PAID', 'DEP004', 0, 'NONE'),
(8, 50000, 'FORFEITED', 'DEP005', 0, 'NONE');
GO

-- 15. Bảng REVIEWS (Đánh giá)
INSERT INTO reviews (customer_id, order_id, product_id, rating, comment, is_visible) VALUES
(5, 1, 1, 5, N'Cà phê rất đậm đà, chuẩn vị', 1),
(6, 2, 2, 4, N'Sữa hơi ngọt một chút', 1),
(7, 3, 5, 5, N'Trà đào miếng to, rất ngon', 1),
(8, 4, 7, 5, N'Đá xay mịn, matcha thơm', 1),
(10, 6, 9, 4, N'Bánh mì ngon nhưng hơi nhỏ', 1),
(7, 3, 8, 5, N'Tiramisu béo ngậy, bánh ngon', 1),
(5, 11, 6, 3, N'Trân châu hơi cứng', 1),
(5, 17, 10, 5, N'Nước ép tươi, rất ưng ý', 1),
(8, 14, 9, 4, N'Bánh mì nóng hổi, tuyệt vời', 1),
(9, 15, 4, 5, N'Bạc xỉu ngon nhất tôi từng uống', 1);
GO

-- 16. Bảng LOYALTY_POINTS (Giao dịch điểm tích lũy)
INSERT INTO loyalty_points (customer_id, transaction_type, points, balance_after, reference_type, reference_id, note) VALUES
(5, 'EARN', 10, 10, 'ORDER', 1, N'Tích điểm mua hàng'),
(6, 'EARN', 5, 5, 'ORDER', 2, N'Tích điểm mua hàng'),
(7, 'EARN', 15, 15, 'ORDER', 3, N'Tích điểm mua hàng'),
(8, 'EARN', 10, 10, 'ORDER', 4, N'Tích điểm mua hàng'),
(10, 'EARN', 20, 20, 'ORDER', 6, N'Tích điểm mua hàng'),
(5, 'EARN', 5, 15, 'REVIEW', 1, N'Tích điểm đánh giá'),
(6, 'EARN', 5, 10, 'REVIEW', 2, N'Tích điểm đánh giá'),
(10, 'REDEEM', -10, 10, 'ORDER', 6, N'Đổi điểm lấy giảm giá'),
(7, 'EARN', 10, 25, 'ORDER', 9, N'Tích điểm mua hàng'),
(5, 'EARN', 10, 25, 'ORDER', 7, N'Tích điểm mua hàng');
GO

-- 17. Bảng POLICIES (Luật / Chính sách điểm)
INSERT INTO policies (policy_name, policy_type, action_type, currency_value, unit, status) VALUES
(N'Giảm giá Sinh nhật', 'REDEEM', 'DISCOUNT', 20, '%', 1),
(N'Tích điểm hóa đơn', 'EARN', 'ORDER', 10, 'point/100k', 1),
(N'Đổi điểm lấy đồ uống', 'REDEEM', 'ORDER', 100, 'points', 1),
(N'Giảm giá khách VIP', 'REDEEM', 'DISCOUNT', 10, '%', 1),
(N'Tặng điểm Review', 'EARN', 'REVIEW', 5, 'points', 1),
(N'Khuyến mãi thứ 3', 'REDEEM', 'DISCOUNT', 15, '%', 1),
(N'Voucher 50k', 'REDEEM', 'DISCOUNT', 50000, 'VND', 1),
(N'Đổi bánh ngọt', 'REDEEM', 'ORDER', 50, 'points', 1),
(N'Mua 2 tính 1', 'REDEEM', 'DISCOUNT', 1, 'item', 1),
(N'Tích điểm check-in', 'EARN', 'ORDER', 2, 'points', 1);
GO

INSERT INTO map (map_name, url_map) VALUES
('Tang 1', 'url1.png'),
('Tang 1', 'url2.png');
GO

-- 19. Bảng SYSTEMLOG (Nhật ký hệ thống)
INSERT INTO system_logs (target_type, target_id, action, ip_address, description) VALUES
('User', 1, 'Login', '192.168.1.2', N'Admin đăng nhập thành công'),
('Product', 1, 'Update', '192.168.1.3', N'Cập nhật giá Espresso'),
('Order', 5, 'Cancel', '192.168.1.10', N'Khách hủy đơn takeaway'),
('Reservation', 8, 'Cancel', '192.168.1.12', N'Quản lý hủy đặt bàn'),
('User', 2, 'Login', '192.168.1.4', N'Manager đăng nhập'),
('Table', 3, 'Update', '192.168.1.4', N'Chuyển trạng thái bàn sang Occupied'),
('Payment', 5, 'Create', '192.168.1.5', N'Nhận thanh toán qua thẻ'),
('Policy', 1, 'Create', '192.168.1.2', N'Thêm chính sách giảm giá Sinh nhật'),
('Review', 3, 'Hide', '192.168.1.2', N'Ẩn review do vi phạm'),
('User', 10, 'Register', '10.0.0.1', N'Khách hàng mới đăng ký tài khoản');
GO

-- 20. customer_addresses ─────────────────────────────────────
-- Chỉ chèn cho user role Customer (role_id = 5): user_id 5, 6, 7, 8, 9, 10
-- user_id 5 → 2 địa chỉ (nhà + cơ quan)
INSERT INTO customer_addresses (customer_id, label, full_address, recipient_name, recipient_phone)VALUES
-- user 5 (Hoàng Văn E)
(5, N'Nhà',      N'12 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM',          N'Hoàng Văn E',  '0901234565'),
(5, N'Cơ quan',  N'Tòa nhà Vietcombank, 5 Công Trường Mê Linh, Quận 1, TP.HCM', N'Hoàng Văn E', '0901234565'),
 
-- user 6 (Đỗ Thị F) — nhưng user 6 role_id=1 (Admin), để đúng thực tế
-- Ta seed cho user_id 5,9,10 là Customer (role_id=5 theo seed gốc)
-- user 9 (Bùi Văn I)
(9, N'Nhà',      N'45 Lê Văn Việt, Phường Hiệp Phú, TP. Thủ Đức, TP.HCM',    N'Bùi Văn I',   '0901234569'),
(9, N'Cơ quan',  N'Đại học Bách Khoa, 268 Lý Thường Kiệt, Quận 10, TP.HCM',  N'Bùi Văn I',   '0901234569'),
 
-- user 10 (Đặng Thị K)
(10, N'Nhà',     N'88 Đinh Tiên Hoàng, Phường 3, Quận Bình Thạnh, TP.HCM',   N'Đặng Thị K',  '0901234570'),
(10, N'Văn phòng', N'Lầu 3, 391A Nam Kỳ Khởi Nghĩa, Quận 3, TP.HCM',        N'Đặng Thị K',  '0901234570');
GO
 
-- 21. carts ──────────────────────────────────────────────────
-- Tạo giỏ hàng cho 3 Customer đang active
-- (user_id 5 = Hoàng Văn E, 9 = Bùi Văn I, 10 = Đặng Thị K)
INSERT INTO carts (customer_id) VALUES
(5),
(9),
(10);
GO
 
-- 22. cart_items ─────────────────────────────────────────────
-- cart_id 1 → customer_id 5
INSERT INTO cart_items (cart_id, product_id, variant_id, quantity, special_note) VALUES
(1, 2,  4,  2, N'Ít đá, nhiều sữa'),        -- Latte Đá Vừa x2
(1, 7,  19, 1, N'Thêm kem cheese'),          -- Matcha Đá Xay Lớn x1
(1, 8,  22, 1, NULL),                       -- Tiramisu Cắt Lát x1
 
-- cart_id 2 → customer_id 9
(2, 3,  7,  1, NULL),                        -- Đen Đá Lớn x1
(2, 9,  24, 2, N'Làm nóng bánh'),           -- Bánh Mì Thêm Pate x2
 
-- cart_id 3 → customer_id 10
(3, 5,  13, 2, N'Ít đá'),                   -- Trà Đào Cam Sả Lớn x2
(3, 6,  16, 1, N'50% đường'),               -- Trà Sữa Size L x1
(3, 10, 27, 1, NULL);                        -- Ép Cam Ít Đường x1
GO
/*
-- 1. Bảng Phân quyền (Roles)
SELECT * FROM roles;

-- 2. Bảng Người dùng/Khách hàng/Nhân viên (Users)
SELECT * FROM users;

-- 3. Bảng Danh mục sản phẩm (Categories)
SELECT * FROM categories;

-- 4. Bảng Sản phẩm (Products)
SELECT * FROM products;

-- 5. Bảng Biến thể sản phẩm (Product Variants)
SELECT * FROM product_variants;

-- 6. Bảng Hình ảnh sản phẩm (Product Images)
SELECT * FROM product_images;

-- 7. Bảng Phương thức thanh toán (Payment Methods)
SELECT * FROM payment_methods;

-- 8. Bảng Bàn trong quán (Tables)
SELECT * FROM tables;

-- 9. Bảng Đơn hàng (Orders)
SELECT * FROM orders;

-- 10. Bảng Chi tiết đơn hàng (Order Details)
SELECT * FROM order_details;

-- 11. Bảng Thanh toán (Payments)
SELECT * FROM payments;

-- 12. Bảng Đặt bàn (Reservations)
SELECT * FROM reservations;

-- 13. Bảng Liên kết Đặt bàn và Bàn (Reservation Tables)
SELECT * FROM reservation_tables;

-- 14. Bảng Tiền cọc đặt bàn (Reservation Deposits)
SELECT * FROM reservation_deposits;

-- 15. Bảng Đánh giá (Reviews)
SELECT * FROM reviews;

-- 16. Bảng Lịch sử điểm tích lũy (Loyalty Points)
SELECT * FROM loyalty_points;

-- 17. Bảng Chính sách tích điểm/giảm giá (Policies)
SELECT * FROM policies;

-- 18. Bảng Sơ đồ mặt bằng quán (Map)
SELECT * FROM map;

-- 19. Bảng Nhật ký hệ thống (System Logs)
SELECT * FROM system_logs;
*/