-- Bakery Management System - Step 1: MySQL 8 schema
CREATE DATABASE IF NOT EXISTS bakery_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bakery_db;

CREATE TABLE Roles (
  RoleId INT AUTO_INCREMENT PRIMARY KEY,
  RoleName VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE Branches (
  BranchId INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(100) NOT NULL,
  Address VARCHAR(255),
  Phone VARCHAR(20),
  IsActive TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE Users (
  UserId INT AUTO_INCREMENT PRIMARY KEY,
  RoleId INT NOT NULL,
  BranchId INT NULL,
  FullName VARCHAR(100) NOT NULL,
  Email VARCHAR(150) NOT NULL UNIQUE,
  Phone VARCHAR(20),
  Address VARCHAR(255),
  PasswordHash VARCHAR(255) NOT NULL,
  IsActive TINYINT(1) NOT NULL DEFAULT 1,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
  FOREIGN KEY (BranchId) REFERENCES Branches(BranchId)
);

CREATE TABLE Suppliers (
  SupplierId INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(100) NOT NULL,
  Email VARCHAR(150),
  Phone VARCHAR(20),
  Address VARCHAR(255)
);

CREATE TABLE Categories (
  CategoryId INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(80) NOT NULL UNIQUE
);

-- Single-row table of global pricing settings (set by Admin)
CREATE TABLE PricingRules (
  PricingRuleId INT AUTO_INCREMENT PRIMARY KEY,
  LaborPct DECIMAL(5,2) NOT NULL DEFAULT 20,
  OverheadPct DECIMAL(5,2) NOT NULL DEFAULT 15,
  MinMarginPct DECIMAL(5,2) NOT NULL DEFAULT 10,
  MaxMarginPct DECIMAL(5,2) NOT NULL DEFAULT 60,
  TaxPct DECIMAL(5,2) NOT NULL DEFAULT 5,
  DeliveryFee DECIMAL(10,2) NOT NULL DEFAULT 150,
  UpdatedBy INT NULL,
  UpdatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (MinMarginPct <= MaxMarginPct),
  FOREIGN KEY (UpdatedBy) REFERENCES Users(UserId)
);

CREATE TABLE RawMaterials (
  RawMaterialId INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(100) NOT NULL UNIQUE,
  Unit VARCHAR(20) NOT NULL,
  UnitCost DECIMAL(10,4) NOT NULL CHECK (UnitCost >= 0),
  StockQty DECIMAL(12,3) NOT NULL DEFAULT 0 CHECK (StockQty >= 0),
  ReorderLevel DECIMAL(12,3) NOT NULL DEFAULT 0,
  SupplierId INT NULL,
  FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId)
);

CREATE TABLE Products (
  ProductId INT AUTO_INCREMENT PRIMARY KEY,
  CategoryId INT NOT NULL,
  Name VARCHAR(120) NOT NULL,
  Description TEXT,
  ImageUrl VARCHAR(255),
  RawMaterialCost DECIMAL(10,2) NOT NULL DEFAULT 0,
  LaborCost DECIMAL(10,2) NOT NULL DEFAULT 0,
  OverheadCost DECIMAL(10,2) NOT NULL DEFAULT 0,
  TotalCost DECIMAL(10,2) NOT NULL DEFAULT 0,
  MarkupPct DECIMAL(5,2) NOT NULL DEFAULT 30,
  SellingPrice DECIMAL(10,2) NOT NULL DEFAULT 0,
  FinalPrice DECIMAL(10,2) NOT NULL DEFAULT 0,
  IsActive TINYINT(1) NOT NULL DEFAULT 1,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
  INDEX idx_products_name (Name)
);

CREATE TABLE RecipeItems (
  ProductId INT NOT NULL,
  RawMaterialId INT NOT NULL,
  Quantity DECIMAL(12,4) NOT NULL CHECK (Quantity > 0),
  PRIMARY KEY (ProductId, RawMaterialId),
  FOREIGN KEY (ProductId) REFERENCES Products(ProductId) ON DELETE CASCADE,
  FOREIGN KEY (RawMaterialId) REFERENCES RawMaterials(RawMaterialId)
);

-- Ready-to-sell stock per branch (employees set it daily)
CREATE TABLE ProductStock (
  BranchId INT NOT NULL,
  ProductId INT NOT NULL,
  Quantity INT NOT NULL DEFAULT 0 CHECK (Quantity >= 0),
  ReorderLevel INT NOT NULL DEFAULT 5,
  PRIMARY KEY (BranchId, ProductId),
  FOREIGN KEY (BranchId) REFERENCES Branches(BranchId),
  FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

CREATE TABLE DailyStockLog (
  LogId INT AUTO_INCREMENT PRIMARY KEY,
  BranchId INT NOT NULL,
  ProductId INT NOT NULL,
  EmployeeId INT NOT NULL,
  LogDate DATE NOT NULL,
  QuantitySet INT NOT NULL CHECK (QuantitySet >= 0),
  UNIQUE (BranchId, ProductId, LogDate),
  FOREIGN KEY (BranchId) REFERENCES Branches(BranchId),
  FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
  FOREIGN KEY (EmployeeId) REFERENCES Users(UserId)
);

CREATE TABLE Orders (
  OrderId INT AUTO_INCREMENT PRIMARY KEY,
  OrderNumber VARCHAR(30) NOT NULL UNIQUE,
  CustomerId INT NULL,               -- NULL for walk-in customers
  EmployeeId INT NULL,               -- set for in-store orders
  BranchId INT NOT NULL,
  OrderType ENUM('Online','InStore') NOT NULL,
  Status ENUM('Pending','Confirmed','Preparing','ReadyForPickup','ReadyForDelivery',
              'OutForDelivery','Delivered','PickedUp','Cancelled') NOT NULL DEFAULT 'Pending',
  Subtotal DECIMAL(10,2) NOT NULL,
  TaxAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
  DeliveryFee DECIMAL(10,2) NOT NULL DEFAULT 0,
  Total DECIMAL(10,2) NOT NULL,
  DeliveryAddress VARCHAR(255),
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (CustomerId) REFERENCES Users(UserId),
  FOREIGN KEY (EmployeeId) REFERENCES Users(UserId),
  FOREIGN KEY (BranchId) REFERENCES Branches(BranchId),
  INDEX idx_orders_customer (CustomerId),
  INDEX idx_orders_status (Status),
  INDEX idx_orders_created (CreatedAt)
);

CREATE TABLE OrderItems (
  OrderItemId INT AUTO_INCREMENT PRIMARY KEY,
  OrderId INT NOT NULL,
  ProductId INT NOT NULL,
  Quantity INT NOT NULL CHECK (Quantity > 0),
  UnitPrice DECIMAL(10,2) NOT NULL,
  LineTotal DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (OrderId) REFERENCES Orders(OrderId) ON DELETE CASCADE,
  FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);

CREATE TABLE Payments (
  PaymentId INT AUTO_INCREMENT PRIMARY KEY,
  OrderId INT NOT NULL,
  Method ENUM('Cash','Card','CashOnDelivery') NOT NULL,
  Amount DECIMAL(10,2) NOT NULL,
  AmountTendered DECIMAL(10,2) NULL,
  ChangeGiven DECIMAL(10,2) NULL,
  TransactionNo VARCHAR(40) NOT NULL UNIQUE,
  InvoiceNo VARCHAR(40) NULL UNIQUE,
  Status ENUM('Pending','Completed','Failed') NOT NULL DEFAULT 'Pending',
  PaidAt DATETIME NULL,
  FOREIGN KEY (OrderId) REFERENCES Orders(OrderId)
);

CREATE TABLE Deliveries (
  DeliveryId INT AUTO_INCREMENT PRIMARY KEY,
  OrderId INT NOT NULL UNIQUE,
  DeliveryStaffId INT NULL,
  Status ENUM('Assigned','Accepted','PickedUp','OnTheWay','Arrived','Delivered') NOT NULL DEFAULT 'Assigned',
  AcceptedAt DATETIME NULL,
  DeliveredAt DATETIME NULL,
  FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
  FOREIGN KEY (DeliveryStaffId) REFERENCES Users(UserId)
);

CREATE TABLE Reviews (
  ReviewId INT AUTO_INCREMENT PRIMARY KEY,
  ProductId INT NOT NULL,
  CustomerId INT NOT NULL,
  Rating TINYINT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
  Comment VARCHAR(1000),
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (ProductId, CustomerId),
  FOREIGN KEY (ProductId) REFERENCES Products(ProductId),
  FOREIGN KEY (CustomerId) REFERENCES Users(UserId)
);

CREATE TABLE PurchaseOrders (
  PurchaseOrderId INT AUTO_INCREMENT PRIMARY KEY,
  BranchId INT NOT NULL,
  SupplierId INT NOT NULL,
  RequestedBy INT NOT NULL,
  Status ENUM('Requested','Approved','Received','Cancelled') NOT NULL DEFAULT 'Requested',
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (BranchId) REFERENCES Branches(BranchId),
  FOREIGN KEY (SupplierId) REFERENCES Suppliers(SupplierId),
  FOREIGN KEY (RequestedBy) REFERENCES Users(UserId)
);

CREATE TABLE PurchaseOrderItems (
  PurchaseOrderId INT NOT NULL,
  RawMaterialId INT NOT NULL,
  Quantity DECIMAL(12,3) NOT NULL CHECK (Quantity > 0),
  UnitCost DECIMAL(10,4) NOT NULL,
  PRIMARY KEY (PurchaseOrderId, RawMaterialId),
  FOREIGN KEY (PurchaseOrderId) REFERENCES PurchaseOrders(PurchaseOrderId) ON DELETE CASCADE,
  FOREIGN KEY (RawMaterialId) REFERENCES RawMaterials(RawMaterialId)
);

CREATE TABLE Notifications (
  NotificationId INT AUTO_INCREMENT PRIMARY KEY,
  BranchId INT NULL,
  Type VARCHAR(30) NOT NULL,          -- e.g. LowStock
  Message VARCHAR(255) NOT NULL,
  IsRead TINYINT(1) NOT NULL DEFAULT 0,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (BranchId) REFERENCES Branches(BranchId)
);

CREATE TABLE AuditLogs (
  LogId BIGINT AUTO_INCREMENT PRIMARY KEY,
  UserId INT NULL,
  Action VARCHAR(100) NOT NULL,
  Details VARCHAR(500),
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Seed data (the admin user is created by the .NET app on first run so the password is hashed properly)
INSERT INTO Roles (RoleName) VALUES ('Customer'),('Employee'),('BranchManager'),('Admin'),('DeliveryStaff');
INSERT INTO Branches (Name, Address, Phone) VALUES ('Main Branch','Multan','0300-0000000');
INSERT INTO PricingRules (LaborPct, OverheadPct, MinMarginPct, MaxMarginPct, TaxPct, DeliveryFee)
VALUES (20, 15, 10, 60, 5, 150);
INSERT INTO Categories (Name) VALUES ('Cakes'),('Breads'),('Pastries'),('Cookies');

USE bakery_db;

CREATE TABLE IF NOT EXISTS PasswordResetCodes (
  PasswordResetCodeId INT AUTO_INCREMENT PRIMARY KEY,
  UserId INT NOT NULL,
  CodeHash VARCHAR(100) NOT NULL,
  ExpiresAt DATETIME NOT NULL,
  Attempts INT NOT NULL DEFAULT 0,
  UsedAt DATETIME NULL,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_prc_user (UserId, CreatedAt),
  FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);

-- Golden Crust Bakery - customer complaint feature
-- Run this once against the existing database after the base schema.
-- MySQL 8.0+

-- Step 16: complaints and deals (run once in MySQL Workbench, after 01_schema.sql and 02_password_reset.sql)
USE bakery_db;
DROP TABLE IF EXISTS Complaints;
 
CREATE TABLE IF NOT EXISTS Complaints (
  ComplaintId INT AUTO_INCREMENT PRIMARY KEY,
  OrderId INT NOT NULL,
  CustomerId INT NOT NULL,
  BranchId INT NOT NULL,
  Message VARCHAR(1000) NOT NULL,
  Status ENUM('Open','Resolved') NOT NULL DEFAULT 'Open',
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ResolvedAt DATETIME NULL,
  ResolvedBy INT NULL,
  INDEX idx_complaints_branch (BranchId, Status),
  INDEX idx_complaints_order (OrderId),
  FOREIGN KEY (OrderId) REFERENCES Orders(OrderId),
  FOREIGN KEY (CustomerId) REFERENCES Users(UserId),
  FOREIGN KEY (BranchId) REFERENCES Branches(BranchId),
  FOREIGN KEY (ResolvedBy) REFERENCES Users(UserId)
);
 
CREATE TABLE IF NOT EXISTS Deals (
  DealId INT AUTO_INCREMENT PRIMARY KEY,
  Title VARCHAR(120) NOT NULL,
  Description VARCHAR(500) NULL,
  CategoryId INT NULL,
  DiscountType ENUM('Percent','Amount') NOT NULL DEFAULT 'Percent',
  DiscountValue DECIMAL(10,2) NOT NULL,
  ImageUrl VARCHAR(255) NULL,
  StartsAt DATETIME NOT NULL,
  EndsAt DATETIME NOT NULL,
  IsActive TINYINT(1) NOT NULL DEFAULT 1,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_deals_active (IsActive, StartsAt, EndsAt),
  CHECK (EndsAt > StartsAt),
  CHECK (DiscountValue > 0),
  FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId)
);
 -- Step 17: combo deals / bundles (run once, after 01, 02, 03)
USE bakery_db;

ALTER TABLE Orders ADD COLUMN BundleDiscount DECIMAL(10,2) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS Bundles (
  BundleId INT AUTO_INCREMENT PRIMARY KEY,
  Title VARCHAR(120) NOT NULL,
  CoreBenefit VARCHAR(500) NULL,
  BundlePrice DECIMAL(10,2) NOT NULL,
  ImageUrl VARCHAR(255) NULL,
  StartsAt DATETIME NOT NULL,
  EndsAt DATETIME NOT NULL,
  IsActive TINYINT(1) NOT NULL DEFAULT 1,
  CreatedBy INT NOT NULL,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_bundles_active (IsActive, StartsAt, EndsAt),
  CHECK (EndsAt > StartsAt),
  CHECK (BundlePrice > 0),
  FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
);

CREATE TABLE IF NOT EXISTS BundleItems (
  BundleId INT NOT NULL,
  ProductId INT NOT NULL,
  Quantity INT NOT NULL DEFAULT 1,
  PRIMARY KEY (BundleId, ProductId),
  CHECK (Quantity > 0),
  FOREIGN KEY (BundleId) REFERENCES Bundles(BundleId) ON DELETE CASCADE,
  FOREIGN KEY (ProductId) REFERENCES Products(ProductId)
);