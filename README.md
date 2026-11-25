# Golden Crust Bakery: Bakery Management System

ASP.NET Core (.NET 10) API + MySQL 8 + plain HTML/CSS/JavaScript. The website is served by the same app.

## Set up (once)
1. Install MySQL Server and .NET 10 SDK.
2. In MySQL Workbench run `01_schema.sql`, then `02_password_reset.sql`.
3. Open `appsettings.json` and set: the MySQL password, a long random `Jwt:Key` (32+ characters), the admin email and password.
4. Optional, for real reset emails: fill in the `Smtp` section (Host, Port, User, Password, From). Left empty, the reset code is printed in the terminal.
5. In this folder run `dotnet restore`, then `dotnet run`.

## Addresses
- Shop: http://localhost:5080
- Staff portal: http://localhost:5080/staff.html
- API docs (Swagger): http://localhost:5080/swagger

## First-time setup in the staff portal (sign in as the admin from appsettings.json)
1. Ingredients: add flour, sugar and so on with cost per unit.
2. Products: add a product, then open Recipe and enter ingredient quantities. The price is calculated automatically.
3. Pricing: check labour %, overhead %, margins, tax and delivery fee.
4. Users: create staff accounts (Employee, BranchManager, DeliveryStaff) with branch 1.
5. Employee signs in and sets today's stock (Daily stock tab). Products show in the shop once they have a recipe.

## Roles
| Role | Can do |
|---|---|
| Customer | Browse, order (cash on delivery), track, cancel before Preparing, review received products, reset password by email |
| Employee | POS sales (cash/card, receipt), online order queue, daily stock |
| BranchManager | Sales dashboard and CSV, stock alerts, reorder requests |
| Admin | Products, recipes, ingredients, pricing rules, users, suppliers, approve purchase orders |
| DeliveryStaff | Accept jobs, update delivery stages, collect cash |

## Order flow
Placed, Confirmed, Preparing, Ready (pickup or delivery), then Picked up or On the way, Arrived, Delivered. Stock is deducted when the order is placed and returned if it is cancelled.

## Troubleshooting
- `Access denied for user 'root'`: wrong MySQL password in `appsettings.json`.
- `Roles not found`: run `01_schema.sql` first.
- `Branch is required` for a staff user: edit the user in Admin > Users and pick a branch.
- Duplicate class errors: you extracted a new zip over an old folder. Delete the old folder first.
