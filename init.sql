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
        "type" int NOT NULL,
        "order_id" int,
        FOREIGN KEY ("type") REFERENCES "page_type" ("id"),
        FOREIGN KEY ("parent_id") REFERENCES "pages" ("id") ON DELETE SET NULL
    );

CREATE TABLE
    "page_content" (
        "id" SERIAL PRIMARY KEY,
        "element_type" int NOT NULL,
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

CREATE UNIQUE INDEX "uc_unique_combination_orders" ON "page_content_order" ("page_id", "content_id", "order_id");

CREATE TABLE "localization" (
  "id" SERIAL PRIMARY KEY,
  "name" varchar NOT NULL
);

CREATE TABLE "page_localization" (
  "id" SERIAL PRIMARY KEY,
  "page_id" int NOT NULL,
  "language" int NOT NULL,
  "title" varchar NOT NULL,
  FOREIGN KEY ("page_id") REFERENCES "pages" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("language") REFERENCES "localization" ("id")
);

CREATE TABLE "page_content_localization" (
  "id" SERIAL PRIMARY KEY,
  "content_id" int NOT NULL,
  "language" int NOT NULL,
  "body" jsonb NOT NULL,
  FOREIGN KEY ("content_id") REFERENCES "page_content" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("language") REFERENCES "localization" ("id")
);


CREATE UNIQUE INDEX "uc_unique_combination_content_localization" ON "page_content_localization" ("content_id", "language", "body");

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

INSERT INTO "localization" ("name") VALUES ('EN'), ('RU'), ('BY');

INSERT INTO
    "pages" (
        "parent_id",
        "type",
        "order_id"
    )
VALUES (NULL, 1, 1), (1, 2, 1);

INSERT INTO "page_localization" ("page_id", "language", "title") VALUES (1, 1, 'TEST_FOLDER'), (2, 1, 'TEST_PAGE');

INSERT INTO
    "page_content" (
        "element_type"
    )
VALUES (
        2
    );


INSERT INTO "page_content_localization" ("content_id", "language", "body") VALUES (1, 1,  '{"content": "Hello, this is test"}':: jsonb);

INSERT INTO "page_content_order" ("page_id", "content_id", "order_id")
VALUES
(
    2, 1, 1
)
