CREATE TABLE
    "user_role" (
        "id" SERIAL PRIMARY KEY,
        "name" varchar UNIQUE NOT NULL
    );

CREATE TABLE
    "page_type" (
        "id" SERIAL PRIMARY KEY,
        "name" varchar UNIQUE NOT NULL
    );

CREATE TABLE
    "page_element_type" (
        "id" SERIAL PRIMARY KEY,
        "name" varchar UNIQUE NOT NULL
    );

CREATE TABLE
    "users" (
        "id" SERIAL PRIMARY KEY,
        "username" varchar UNIQUE NOT NULL,
        "role" int NOT NULL,
        "pass" varchar NOT NULL,
        FOREIGN KEY ("role") REFERENCES "user_role" ("id")
    );

CREATE TABLE
    "pages" (
        "id" SERIAL PRIMARY KEY,
        "parent_id" int,
        "title" varchar NOT NULL,
        "type" int NOT NULL,
        "order_id" int,
        FOREIGN KEY ("type") REFERENCES "page_type" ("id"),
        FOREIGN KEY ("parent_id") REFERENCES "pages" ("id")
    );

CREATE TABLE
    "page_content" (
        "id" SERIAL PRIMARY KEY,
        "element_type" int NOT NULL,
        "body" jsonb NOT NULL,
        FOREIGN KEY ("element_type") REFERENCES "page_element_type" ("id")
    );

CREATE TABLE
    "page_content_order" (
        "id" SERIAL PRIMARY KEY,
        "page_id" int NOT NULL,
        "content_id" int NOT NULL,
        "order_id" int NOT NULL,
        FOREIGN KEY ("page_id") REFERENCES "pages" ("id"),
        FOREIGN KEY ("content_id") REFERENCES "page_content" ("id") ON DELETE CASCADE
    );

CREATE UNIQUE INDEX "uc_unique_combination" ON "page_content" ("element_type", "body");
CREATE UNIQUE INDEX "uc_unique_combination_orders" ON "page_content_order" ("page_id", "content_id", "order_id");

CREATE OR REPLACE FUNCTION delete_page_content_if_no_orders()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM page_content
  WHERE id = OLD.content_id
  AND NOT EXISTS (
    SELECT 1 FROM page_content_order
    WHERE content_id = OLD.content_id
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_page_content_trigger
AFTER DELETE ON page_content_order
FOR EACH ROW
EXECUTE FUNCTION delete_page_content_if_no_orders();




INSERT INTO "page_type" ("name") VALUES ('FOLDER'), ('PAGE');

INSERT INTO "page_element_type" ("name") VALUES ('IMAGE'), ('TEXT');

INSERT INTO "user_role" ("name") VALUES ('ROLE_ADMIN');

INSERT INTO
    "pages" (
        "parent_id",
        "title",
        "type",
        "order_id"
    )
VALUES (NULL, 'TEST_FOLDER', 1, 1), (1, 'TEST_PAGE', 2, 1);

INSERT INTO
    "page_content" (
        "element_type",
        "body"
    )
VALUES (
        2,
        '{"content": "Hello, this is test"}':: jsonb
    );

INSERT INTO "page_content_order" ("page_id", "content_id", "order_id")
VALUES 
(
    2, 1, 1
)