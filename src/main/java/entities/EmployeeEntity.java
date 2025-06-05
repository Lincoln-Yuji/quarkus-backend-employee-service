package entities;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "Employees")
public class EmployeeEntity extends PanacheEntityBase
{
    @Id
    @Column(length = 7, nullable = false, unique = true)
    public String id;

    @Column(nullable = false)
    public String name;

    @Column(nullable = false, unique = true)
    public String email;
}