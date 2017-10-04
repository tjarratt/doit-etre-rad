CREATE TABLE phrases (
    uuid varchar(36) NOT NULL,
    user_uuid varchar(36) NOT NULL,
    phrase TEXT NOT NULL,
    phrase_type TEXT NOT NULL,

    PRIMARY KEY (uuid)
);
