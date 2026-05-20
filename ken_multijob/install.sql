-- Add job2 and job2_grade columns to users table
-- Run this SQL in your database

ALTER TABLE `users` 
ADD COLUMN `job2` VARCHAR(50) DEFAULT 'unemployed' AFTER `job_grade`,
ADD COLUMN `job2_grade` INT(11) DEFAULT 0 AFTER `job2`;

-- Optional: Update existing users to have unemployed as second job
UPDATE `users` SET `job2` = 'unemployed', `job2_grade` = 0 WHERE `job2` IS NULL;
