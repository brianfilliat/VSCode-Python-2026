# GoDaddy SRE Interview: Conversational STAR Examples

This guide is designed to help you communicate your technical expertise in a way that is engaging, clear, and focused on real-world impact. During a Site Reliability Engineering (SRE) interview at GoDaddy, the goal is to demonstrate that you possess both the technical depth to solve complex problems and the communication skills to collaborate effectively within a team.

## 1. Scalable Storage and Proactive Troubleshooting

In this example, you describe your work with Ceph and Kubernetes at Microland. The focus is on your ability to handle complex integrations and optimize performance under pressure.

**The Narrative**
At Microland, our transition to Kubernetes introduced a significant challenge: our stateful applications were struggling because our existing storage solutions could not scale or perform at the required level. I was tasked with building a foundation that was both resilient and capable of growing alongside our workloads. I chose Ceph for its distributed architecture and flexibility. Rather than simply installing the software, I implemented a comprehensive monitoring system using Prometheus and Grafana. This allowed me to detect performance bottlenecks early, specifically identifying a network latency issue between storage nodes. By optimizing the Maximum Transmission Unit (MTU) settings and creating a dedicated network segment for storage traffic, I was able to eliminate the bottleneck.

| Metric | Outcome |
| :--- | :--- |
| **Incident Reduction** | 20% decrease in storage-related tickets |
| **Performance Gain** | 15% improvement in IOPS for critical apps |
| **Stakeholder Impact** | Restored developer confidence in data persistence |

## 2. Eliminating Operational Toil through Automation

This story highlights your mindset regarding efficiency and reliability, which are core tenets of SRE. It focuses on your work at Dell Technologies.

**The Narrative**
During my time at Dell, I noticed that our team was losing significant hours every week to "click-and-wait" tasks, such as manual provisioning and health checks. These repetitive processes were not only slow but also prone to human error. I took the initiative to transform our manual runbooks into executable code using a combination of Python scripts and Ansible playbooks. By integrating these tools into our Jenkins CI/CD pipelines, I enabled a self-service model for storage provisioning. This meant that instead of a manual afternoon-long process, the system could automatically and accurately deploy resources in a matter of minutes.

| Achievement | Impact |
| :--- | :--- |
| **Provisioning Time** | Reduced by 70% |
| **Reliability** | Eliminated manual configuration typos |
| **Team Focus** | Shifted effort from "toil" to strategic projects |

## 3. High-Stakes Migration and Risk Management

This example demonstrates your ability to manage high-risk operations with a focus on data integrity and collaboration. It centers on your experience at Unisys.

**The Narrative**
At Unisys, I led a high-stakes project to migrate critical Oracle RAC clusters from aging VMAX hardware to modern PowerMax systems. Because these databases supported core business functions, any unplanned downtime would have been catastrophic. I approached the migration as a phased operation, emphasizing meticulous planning and cross-functional collaboration. I worked closely with the AIX and application teams in a "war room" environment to ensure everyone was aligned. We treated every phase as a learning opportunity, conducting blameless post-mortems to refine our strategy. This collaborative and structured approach ensured that we completed the migration with zero unplanned downtime and perfect data integrity.

| Key Strategy | Result |
| :--- | :--- |
| **Phased Rollout** | Minimized risk and allowed for validation at every step |
| **Blameless Culture** | Improved the migration playbook by 10% in speed |
| **Operational Success** | 100% data integrity with zero unplanned downtime |

## 4. Enhancing Observability and Proactive Response

This story focuses on your ability to build "radar systems" for infrastructure, moving from a reactive to a proactive operational model.

**The Narrative**
In a previous environment, we were plagued by intermittent performance issues that were difficult to diagnose because we lacked centralized visibility. We were often the last to know when a system was failing, relying on user reports rather than our own data. To fix this, I designed and deployed a modern observability stack using Prometheus, Grafana, and Loki. I didn't just build dashboards; I created a unified view of system health by integrating these tools with our existing Icinga2 monitoring. This gave us the ability to see trends and anomalies before they impacted users, transforming our team from "firefighters" into proactive system guardians.

| KPI | Improvement |
| :--- | :--- |
| **Detection Speed** | 40% reduction in Mean Time to Detection (MTTD) |
| **Resolution Speed** | 30% reduction in Mean Time to Resolution (MTTR) |
| **Operational State** | Shifted from reactive "firefighting" to proactive monitoring |

## 5. Secure Cloud Architecture in AWS

This final example showcases your expertise in cloud-native security and Kubernetes orchestration within the AWS ecosystem.

**The Narrative**
As a Cloud Platform Engineer, I worked with enterprise clients who had extremely high standards for security and compliance. My role involved deploying production workloads on Amazon EKS while ensuring that the infrastructure was a "secure playground." I architected VPC environments from the ground up, strictly enforcing the principle of least privilege for all access controls. By automating the entire infrastructure provisioning process with Python, I ensured that every environment was consistent, repeatable, and audit-ready. This balance of automation and security allowed our clients to move quickly without compromising their compliance requirements.

| Focus Area | Implementation Detail |
| :--- | :--- |
| **Security** | Strict VPC isolation and least-privilege IAM roles |
| **Consistency** | 100% automated infrastructure via Python and CI/CD |
| **Compliance** | Met stringent enterprise security standards for production |

---

### Interview Delivery Advice

When presenting these stories, remember that the interviewer is looking for your "SRE mindset." Use the word **"I"** to describe your specific actions, but use **"we"** to acknowledge the importance of team collaboration. After finishing a story, consider asking a follow-up question such as, "Is this similar to the types of scaling challenges the team at GoDaddy is currently solving?" This turns the interview into a two-way conversation and shows your genuine interest in their environment.
