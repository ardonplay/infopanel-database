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

CREATE TABLE "localization_type" (
  "id" SERIAL PRIMARY KEY,
  "name" varchar NOT NULL
);

CREATE TABLE
    "user" (
        "id" uuid NOT NULL DEFAULT (gen_random_uuid()) PRIMARY KEY,
        "username" varchar UNIQUE NOT NULL,
        "role" int NOT NULL,
        "pass" varchar NOT NULL,
        FOREIGN KEY ("role") REFERENCES "user_role" ("id")
    );

CREATE TABLE
    "page" (
        "id" uuid NOT NULL DEFAULT (gen_random_uuid()) PRIMARY KEY,
        "parent_id" uuid,
        "type" int NOT NULL,
        "order_id" int,
        FOREIGN KEY ("type") REFERENCES "page_type" ("id"),
        FOREIGN KEY ("parent_id") REFERENCES "page" ("id") ON DELETE SET NULL
    );

CREATE TABLE
    "page_content" (
        "id" uuid NOT NULL DEFAULT (gen_random_uuid()) PRIMARY KEY,
        "element_type" int NOT NULL,
        FOREIGN KEY ("element_type") REFERENCES "page_element_type" ("id")
    );

CREATE TABLE
    "page_content_order" (
        "id" uuid NOT NULL DEFAULT (gen_random_uuid()) PRIMARY KEY,
        "page_id" uuid NOT NULL,
        "content_id" uuid NOT NULL,
        "order_id" int NOT NULL,
        FOREIGN KEY ("page_id") REFERENCES "page" ("id"),
        FOREIGN KEY ("content_id") REFERENCES "page_content" ("id") ON DELETE CASCADE
    );

CREATE UNIQUE INDEX "uc_unique_combination_orders" ON "page_content_order" ("page_id", "content_id", "order_id");

CREATE TABLE "page_localization" (
  "id" uuid NOT NULL DEFAULT (gen_random_uuid()) PRIMARY KEY,
  "page_id" uuid NOT NULL,
  "language" int NOT NULL,
  "title" varchar NOT NULL,
  FOREIGN KEY ("page_id") REFERENCES "page" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("language") REFERENCES "localization_type" ("id")
);

CREATE TABLE "page_content_localization" (
  "id" uuid NOT NULL DEFAULT (gen_random_uuid()) PRIMARY KEY,
  "content_id" uuid NOT NULL,
  "language" int NOT NULL,
  "body" jsonb NOT NULL,
  FOREIGN KEY ("content_id") REFERENCES "page_content" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("language") REFERENCES "localization_type" ("id")
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

INSERT INTO "localization_type" ("name") VALUES ('EN'), ('RU'), ('BY');

INSERT INTO
    "page" (
        "parent_id",
        "type",
        "order_id"
    )
VALUES (NULL, 1, 1);

INSERT INTO
    "page" (
        "parent_id",
        "type",
        "order_id"
    )
VALUES ((SELECT page.id FROM "page" LIMIT 1 OFFSET 0), 2, 1);

INSERT INTO "page_localization" ("page_id", "language", "title") VALUES ((SELECT page.id FROM "page" LIMIT 1 OFFSET 0), 1, 'TEST_FOLDER'), ((SELECT page.id FROM "page" LIMIT 1 OFFSET 1), 1, 'TEST_PAGE');

INSERT INTO
    "page_content" (
        "element_type"
    )
VALUES (
        2
    );


INSERT INTO "page_content_localization" ("content_id", "language", "body") VALUES ((SELECT id FROM "page_content" LIMIT 1 OFFSET 0), 1,  '{"content": "Hello, this is test"}':: jsonb);

INSERT INTO "page_content_order" ("page_id", "content_id", "order_id")
VALUES
(
    (SELECT page.id FROM "page" LIMIT 1 OFFSET 1), (SELECT id FROM "page_content" LIMIT 1 OFFSET 0), 1
);

INSERT INTO "user" ("username", "pass", "role") VALUES ('admin', '$2a$12$TaALbtn256eJu/agCXSgpuJdwVymEncysl1UIWE0.acddcCbCB8fe', 1);
