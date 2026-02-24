# Backend .env Setup Guide

## Location
Create or update the `.env` file in your backend directory: `D:\gymsasapp\backend\.env`

## Required .env Configuration

```env
# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# API Configuration
API_URL=http://localhost:3001
NODE_ENV=development

# Database Configuration (if using database)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gymsas_db
DB_USER=postgres
DB_PASSWORD=your-db-password

# AWS Configuration (for face recognition)
AWS_REGION=your-aws-region
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Upload Configuration
MAX_FILE_SIZE=52428800
UPLOAD_DIR=./uploads

# Server Configuration
PORT=3001
```

## Steps to Create/Update .env File

1. Navigate to your backend directory:
   ```
   cd D:\gymsasapp\backend
   ```

2. Create or open the `.env` file:
   ```
   # On Windows PowerShell
   New-Item -Path ".env" -ItemType "file"
   # Or use any text editor to create/edit the file
   ```

3. Add the configuration values shown above

4. Save the file

5. Restart your backend server to apply the changes

## Important Notes

- **JWT_SECRET**: Use a strong, random string in production. Generate one using:
  - Node.js: `require('crypto').randomBytes(32).toString('hex')`
  - Or use an online generator

- **Never commit** the `.env` file to version control
- Add `.env` to your `.gitignore` file

- Update all placeholder values with your actual configuration

- The backend will read these environment variables when it starts

