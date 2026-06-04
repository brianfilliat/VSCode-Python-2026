CREATE TABLE `content_revisions` (
	`id` int AUTO_INCREMENT NOT NULL,
	`sectionId` int,
	`tableId` int,
	`noteId` int,
	`originalContent` text NOT NULL,
	`modifiedContent` text,
	`modifiedBy` int,
	`revisionNumber` int NOT NULL DEFAULT 1,
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	CONSTRAINT `content_revisions_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `training_notes` (
	`id` int AUTO_INCREMENT NOT NULL,
	`sectionId` int NOT NULL,
	`noteType` enum('definition','example','tip','warning') NOT NULL,
	`title` varchar(255),
	`content` text NOT NULL,
	`order` int NOT NULL DEFAULT 0,
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	`updatedAt` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `training_notes_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `training_sections` (
	`id` int AUTO_INCREMENT NOT NULL,
	`topicId` int NOT NULL,
	`title` varchar(255) NOT NULL,
	`content` text,
	`order` int NOT NULL DEFAULT 0,
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	`updatedAt` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `training_sections_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `training_table_rows` (
	`id` int AUTO_INCREMENT NOT NULL,
	`tableId` int NOT NULL,
	`rowData` text,
	`order` int NOT NULL DEFAULT 0,
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	`updatedAt` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `training_table_rows_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `training_tables` (
	`id` int AUTO_INCREMENT NOT NULL,
	`sectionId` int NOT NULL,
	`title` varchar(255) NOT NULL,
	`tableName` varchar(255) NOT NULL,
	`columns` text,
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	`updatedAt` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `training_tables_id` PRIMARY KEY(`id`)
);
--> statement-breakpoint
CREATE TABLE `training_topics` (
	`id` int AUTO_INCREMENT NOT NULL,
	`title` varchar(255) NOT NULL,
	`slug` varchar(255) NOT NULL,
	`description` text,
	`icon` varchar(64),
	`order` int NOT NULL DEFAULT 0,
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	`updatedAt` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `training_topics_id` PRIMARY KEY(`id`),
	CONSTRAINT `training_topics_slug_unique` UNIQUE(`slug`)
);
