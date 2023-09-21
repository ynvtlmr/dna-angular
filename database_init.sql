-- Delete everything --
DO $$
DECLARE
   table_name text;
BEGIN
   FOR table_name IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
   LOOP
      EXECUTE 'DROP TABLE IF EXISTS ' || table_name || ' CASCADE';
   END LOOP;
END $$;


-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table for Agency
CREATE TABLE Agency (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agency_name VARCHAR(255)
);
ALTER TABLE Agency ENABLE ROW LEVEL SECURITY;
ALTER TABLE Agency FORCE ROW LEVEL SECURITY;

-- Table for Advisor
CREATE TABLE Advisor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supabase_user_id UUID UNIQUE,
    advisor_name VARCHAR(255),
    agency_id UUID REFERENCES Agency(id)
);
ALTER TABLE Advisor ENABLE ROW LEVEL SECURITY;
ALTER TABLE Advisor FORCE ROW LEVEL SECURITY;

-- Table for Client
CREATE TABLE Client (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_name VARCHAR(255),
    birthdate DATE,
    province VARCHAR(255),
    annual_income FLOAT,
    income_replacement_multiplier INT,
    advisor_id UUID REFERENCES Advisor(id)
);
ALTER TABLE Client ENABLE ROW LEVEL SECURITY;
ALTER TABLE Client FORCE ROW LEVEL SECURITY;

-- Table for Beneficiary
CREATE TABLE Beneficiary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    beneficiary_name VARCHAR(255),
    default_allocation FLOAT
);

-- Abstract table for FinancialInstrument
CREATE TABLE FinancialInstrument (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    financial_instrument_name VARCHAR(255),
    purchase_price FLOAT,
    year_acquired INT,
    current_value FLOAT,
    rate FLOAT,
    term INT,
    client_id UUID REFERENCES Client(id)
);
ALTER TABLE FinancialInstrument ENABLE ROW LEVEL SECURITY;
ALTER TABLE FinancialInstrument FORCE ROW LEVEL SECURITY;

-- Table for Asset, inherits from FinancialInstrument
CREATE TABLE Asset (
    id UUID PRIMARY KEY REFERENCES FinancialInstrument(id),
    is_taxable BOOLEAN,
    is_to_be_sold BOOLEAN,
    is_liquid BOOLEAN
);
ALTER TABLE Asset ENABLE ROW LEVEL SECURITY;
ALTER TABLE Asset FORCE ROW LEVEL SECURITY;

-- Table for AssetBeneficiaryAllocation
CREATE TABLE AssetBeneficiaryAllocation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID REFERENCES Asset(id),
    beneficiary_id UUID REFERENCES Beneficiary(id),
    allocation FLOAT
);
ALTER TABLE AssetBeneficiaryAllocation ENABLE ROW LEVEL SECURITY;
ALTER TABLE AssetBeneficiaryAllocation FORCE ROW LEVEL SECURITY;

-- Table for Debt, inherits from FinancialInstrument
CREATE TABLE Debt (
    id UUID PRIMARY KEY REFERENCES FinancialInstrument(id),
    annual_payment FLOAT
);
ALTER TABLE Debt ENABLE ROW LEVEL SECURITY;
ALTER TABLE Debt FORCE ROW LEVEL SECURITY;

-- Table for Goal
CREATE TABLE Goal (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    goal_name VARCHAR(255),
    dollar_amount FLOAT,
    is_philanthropic BOOLEAN,
    client_id UUID REFERENCES Client(id)
);
ALTER TABLE Goal ENABLE ROW LEVEL SECURITY;
ALTER TABLE Goal FORCE ROW LEVEL SECURITY;

-- Table for Business
CREATE TABLE Business (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255),
    valuation FLOAT,
    rate FLOAT,
    term INT
);
ALTER TABLE Business ENABLE ROW LEVEL SECURITY;
ALTER TABLE Business FORCE ROW LEVEL SECURITY;

-- Table for Shareholder
CREATE TABLE Shareholder (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shareholder_name VARCHAR(255),
    share_percentage FLOAT,
    insurance_coverage FLOAT,
    business_id UUID REFERENCES Business(id),
    client_id UUID REFERENCES Client(id) NULL
);
ALTER TABLE Shareholder ENABLE ROW LEVEL SECURITY;
ALTER TABLE Shareholder FORCE ROW LEVEL SECURITY;

-- Prevent deletion of an Advisor that has Clients --
CREATE OR REPLACE FUNCTION prevent_advisor_deletion()
RETURNS TRIGGER AS $$
DECLARE
  client_count INT;
BEGIN
  SELECT COUNT(*) INTO client_count FROM Client WHERE advisor_id = OLD.id;
  IF client_count > 0 THEN
    RAISE EXCEPTION 'Cannot delete Advisor with associated Clients';
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_advisor_deletion_trigger
BEFORE DELETE ON Advisor
FOR EACH ROW EXECUTE FUNCTION prevent_advisor_deletion();

-- create Payments table --
CREATE TABLE Payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agency_id UUID REFERENCES Agency(id),
    amount FLOAT,
    payment_date DATE,
    status VARCHAR(50)
);
